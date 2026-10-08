import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'disease_classifier.dart';
import 'notification_service.dart';

/// A single disease-detection scan result.
class ScanResult {
  final String id;
  final String diagnosis;
  final String cropType;
  final String scientificName;
  final double confidence;
  final String severity; // 'low' | 'moderate' | 'high'
  final String symptoms;
  final String treatment;
  /// Short, shop-searchable term (e.g. "fungicide", "copper
  /// fungicide") used to pre-fill the Suppliers screen's search box.
  /// Can be empty for cases with no purchasable treatment (e.g. viral
  /// diseases where the only action is removing infected plants) —
  /// in that case SuppliersScreen falls back to a general nearby
  /// search instead of searching for an empty term.
  final String treatmentKeyword;
  final String? userNotes;
  final String imageUrl;
  final DateTime createdAt;
  final bool isLowConfidence;

  ScanResult({
    required this.id,
    required this.diagnosis,
    required this.cropType,
    required this.scientificName,
    required this.confidence,
    required this.severity,
    required this.symptoms,
    required this.treatment,
    required this.treatmentKeyword,
    required this.userNotes,
    required this.imageUrl,
    required this.createdAt,
    required this.isLowConfidence,
  });

  factory ScanResult.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ScanResult(
      id: doc.id,
      diagnosis: data['diagnosis'] ?? 'Unknown',
      cropType: data['cropType'] ?? '',
      scientificName: data['scientificName'] ?? '',
      confidence: (data['confidence'] ?? 0).toDouble(),
      severity: data['severity'] ?? 'moderate',
      symptoms: data['symptoms'] ?? '',
      treatment: data['treatment'] ?? '',
      treatmentKeyword: data['treatmentKeyword'] ?? '',
      userNotes: data['userNotes'],
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLowConfidence: data['isLowConfidence'] ?? false,
    );
  }
}

class DiseaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DiseaseClassifier _classifier = DiseaseClassifier();
  final NotificationService _notificationService = NotificationService();

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestore.collection('disease_history');

  /// Uploads a locally-captured image file to Supabase Storage and
  /// returns its public URL.
  Future<String> uploadScanImage(File imageFile) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final fileName = 'scans/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from('disease-images').upload(fileName, imageFile);
    return _supabase.storage.from('disease-images').getPublicUrl(fileName);
  }

  /// Runs real on-device disease classification (TensorFlow Lite) on
  /// the captured photo, then saves the result to Firestore.
  ///
  /// Model: MobileNetV2 transfer learning, fine-tuned (Phase 2),
  /// 95.31% accuracy on a 3,157-image held-out test set. Covers 25
  /// classes across Apple, Corn, Grape, Potato, and Tomato only —
  /// other crops are not yet supported by this model (see the
  /// project's Data Collection report for the full roadmap).
  Future<ScanResult> analyzeAndSave({
    required File imageFile,
    required String userNotes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User must be signed in to scan a crop.');

    // Run inference and upload in parallel — they're independent.
    final results = await Future.wait([
      _classifier.classify(imageFile),
      uploadScanImage(imageFile),
    ]);
    final classification = results[0] as ClassificationResult;
    final imageUrl = results[1] as String;

    final data = {
      'uid': uid,
      'diagnosis': classification.diagnosis,
      'cropType': classification.cropType,
      'scientificName': '', // TODO: add scientific names to disease_classifier.dart if desired
      'confidence': classification.confidence,
      'severity': classification.severity,
      'symptoms': classification.symptoms,
      'treatment': classification.treatment,
      'treatmentKeyword': classification.treatmentKeyword,
      'userNotes': userNotes.trim().isEmpty ? null : userNotes.trim(),
      'imageUrl': imageUrl,
      'isLowConfidence': classification.isLowConfidence,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _historyCollection.add(data);
    final saved = await docRef.get();
    final result = ScanResult.fromFirestore(saved);

    // Fire-and-forget — don't block returning the result on this.
    _notificationService.notifyScanSaved(diagnosis: result.diagnosis);

    return result;
  }

  /// Live stream of the current user's scan history, most recent first.
  Stream<List<ScanResult>> streamUserHistory() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _historyCollection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ScanResult.fromFirestore).toList());
  }

  /// Deletes a scan from history — removes the Firestore record and
  /// best-effort deletes the associated photo from Supabase Storage
  /// (storage cleanup failure doesn't block the record deletion,
  /// since an orphaned image file is a minor issue while a stuck
  /// history entry is a worse user-facing problem).
  Future<void> deleteScan(ScanResult scan) async {
    try {
      final uri = Uri.parse(scan.imageUrl);
      final marker = '/disease-images/';
      final markerIndex = uri.path.indexOf(marker);
      if (markerIndex != -1) {
        final storagePath = uri.path.substring(markerIndex + marker.length);
        await _supabase.storage.from('disease-images').remove([storagePath]);
      }
    } catch (e) {
      // Non-fatal — proceed to delete the Firestore record regardless.
    }

    await _historyCollection.doc(scan.id).delete();
  }
}