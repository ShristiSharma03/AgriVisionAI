import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Result of running the on-device model on a captured photo.
class ClassificationResult {
  final String cropType;
  final String diagnosis; // "Healthy" or the disease name
  final bool isHealthy;
  final double confidence; // 0.0 - 1.0
  final String symptoms;
  final String treatment;
  /// Short, shop-searchable term (e.g. "fungicide", "copper
  /// fungicide", "bactericide") — distinct from the longer
  /// human-readable `treatment` sentence. Used to pre-fill the
  /// Suppliers screen's search box, since matching shop names against
  /// a full sentence returns poor results compared to a short term.
  final String treatmentKeyword;
  final String severity; // 'low' | 'moderate' | 'high'
  final bool isLowConfidence; // true if below the reliability threshold

  ClassificationResult({
    required this.cropType,
    required this.diagnosis,
    required this.isHealthy,
    required this.confidence,
    required this.symptoms,
    required this.treatment,
    required this.treatmentKeyword,
    required this.severity,
    required this.isLowConfidence,
  });
}

/// Loads and runs the TensorFlow Lite disease-detection model
/// on-device (offline).
///
/// Matches the confirmed AgriVisionAI ML handoff state: 25 classes,
/// Kaggle abdallahalidev/plantvillage-dataset (color variant),
/// MobileNetV2 transfer learning, 224x224 input, 95.31% test accuracy
/// (Phase 2 fine-tuned model).
///
/// CRITICAL — preprocessing: the saved model has MobileNetV2's
/// preprocess_input step BUILT INTO the model graph itself (visible
/// as true_divide/subtract layers in the model summary). This means
/// the model expects RAW 0-255 pixel values as input — NOT manually
/// normalized to [0,1] or [-1,1]. The project's own diagnostic
/// (comparing raw vs. manually-normalized input) confirmed that
/// manual normalization causes a preprocessing mismatch that breaks
/// predictions almost entirely (dropping from 99.98% confidence on
/// the correct class to a wrong class at 95% confidence). Do NOT
/// add any /255 or /127.5-1 scaling here — feed raw pixel values.
///
/// SETUP REQUIRED:
/// 1. Copy agrivision_mobilenetv2_final.tflite and labels.txt into
///    assets/model/.
/// 2. Add to pubspec.yaml under flutter: -> assets:
///      - assets/model/agrivision_mobilenetv2_final.tflite
///      - assets/model/labels.txt
/// 3. Add dependencies: tflite_flutter, image
class DiseaseClassifier {
  static const int _inputSize = 224;
  // Below this confidence, the app tells the farmer the photo is
  // unclear rather than confidently naming a disease — since the
  // model has no explicit "unknown" class and will otherwise force
  // any image (including unsupported crops or blurry photos) into
  // one of its 25 known categories. Threshold chosen conservatively;
  // adjust based on real-world testing per the ML handoff's guidance.
  static const double _confidenceThreshold = 0.60;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> loadModel() async {
    if (_isReady) return;
    _interpreter = await Interpreter.fromAsset('assets/model/agrivision_mobilenetv2_final.tflite');
    final labelsText = await rootBundle.loadString('assets/model/labels.txt');
    _labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    _isReady = true;
  }

  Future<ClassificationResult> classify(File imageFile) async {
    if (!_isReady || _interpreter == null) {
      await loadModel();
    }

    final rawBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) throw Exception('Could not decode captured image.');

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize, interpolation: img.Interpolation.linear);

    // Feed RAW 0-255 pixel values (as float32) — the model's own
    // embedded preprocessing layers handle the MobileNetV2 scaling.
    // See the class-level doc comment above for why this matters.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    var bestIndex = 0;
    var bestScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }

    final rawLabel = _labels[bestIndex];
    return _buildResult(rawLabel, bestScore.toDouble());
  }

  ClassificationResult _buildResult(String rawLabel, double confidence) {
    final isLowConfidence = confidence < _confidenceThreshold;

    final parts = rawLabel.split('___');
    // Clean up crop display name: "Corn_(maize)" -> "Corn", "Apple" -> "Apple"
    final cropType = parts[0]
        .replaceAll(RegExp(r'_\(.*?\)'), '') // strip "_(maize)" etc.
        .replaceAll('_', ' ')
        .trim();
    final diseaseRaw = parts.length > 1 ? parts[1] : 'Unknown';
    final isHealthy = diseaseRaw.toLowerCase().contains('healthy');
    // Trim any trailing underscore quirks from the Kaggle folder names
    // (e.g. "Common_rust_") before turning into a display string.
    final diseaseName = isHealthy
        ? 'Healthy'
        : diseaseRaw.replaceAll(RegExp(r'_+$'), '').replaceAll('_', ' ');

    if (isLowConfidence) {
      return ClassificationResult(
        cropType: cropType,
        diagnosis: diseaseName,
        isHealthy: isHealthy,
        confidence: confidence,
        symptoms: 'The image is unclear, or this crop/disease may not be one of the '
            '25 categories this model currently supports (Apple, Corn, Grape, '
            'Potato, Tomato). Try retaking the photo in better light, closer to '
            'the leaf, against a plain background.',
        treatment: 'Please retake the photo, or consult a local agricultural '
            'extension officer if the issue persists.',
        treatmentKeyword: '',
        severity: 'low',
        isLowConfidence: true,
      );
    }

    final info = _diseaseInfo[rawLabel] ??
        _DiseaseInfo(
          symptoms: isHealthy
              ? 'No visible signs of disease detected on this leaf.'
              : 'Visible discoloration or lesions detected on the leaf surface.',
          treatment: isHealthy
              ? 'Continue regular monitoring and good field hygiene.'
              : 'Consult a local agricultural extension officer for a targeted treatment plan.',
          treatmentKeyword: isHealthy ? '' : 'fungicide',
          severity: isHealthy ? 'low' : 'moderate',
        );

    return ClassificationResult(
      cropType: cropType,
      diagnosis: diseaseName,
      isHealthy: isHealthy,
      confidence: confidence,
      symptoms: info.symptoms,
      treatment: info.treatment,
      treatmentKeyword: info.treatmentKeyword,
      severity: info.severity,
      isLowConfidence: false,
    );
  }

  void dispose() {
    _interpreter?.close();
    _isReady = false;
  }
}

class _DiseaseInfo {
  final String symptoms;
  final String treatment;
  final String treatmentKeyword;
  final String severity;
  const _DiseaseInfo({
    required this.symptoms,
    required this.treatment,
    required this.treatmentKeyword,
    required this.severity,
  });
}

/// Symptom/treatment reference, keyed by the EXACT 25 class labels
/// confirmed in the AgriVisionAI ML handoff (Kaggle folder names,
/// including their quirks like "_(maize)" and trailing underscores).
/// This order/spelling must match labels.txt exactly for lookups to work.
///
/// treatmentKeyword is intentionally short and generic (e.g.
/// "fungicide", "copper fungicide", "bactericide", "insecticide") —
/// specific product/brand names are deliberately left out since
/// registered products vary by region and change over time. These
/// short terms are what actually gets searched against nearby shop
/// names in the Suppliers screen.
final Map<String, _DiseaseInfo> _diseaseInfo = {
  'Apple___Apple_scab': const _DiseaseInfo(
    symptoms: 'Olive-green to black velvety spots on leaves and fruit.',
    treatment: 'Apply fungicide starting at bud break, rake and destroy fallen leaves in autumn.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Apple___Black_rot': const _DiseaseInfo(
    symptoms: 'Purple-bordered leaf spots, brown rot with concentric rings on fruit.',
    treatment: 'Prune out dead/diseased wood, apply fungicide, remove mummified fruit.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Apple___Cedar_apple_rust': const _DiseaseInfo(
    symptoms: 'Bright orange-yellow spots on upper leaf surface.',
    treatment: 'Apply fungicide in spring, remove nearby cedar trees if possible (alternate host).',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Corn___Cercospora_leaf_spot Gray_leaf_spot': const _DiseaseInfo(
    symptoms: 'Rectangular gray-brown lesions running parallel to leaf veins.',
    treatment: 'Apply fungicide, rotate crops, avoid dense planting for better airflow.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Corn___Common_rust_': const _DiseaseInfo(
    symptoms: 'Small reddish-brown pustules scattered across both leaf surfaces.',
    treatment: 'Apply fungicide if severe; plant rust-resistant corn varieties in future seasons.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Corn___Northern_Leaf_Blight': const _DiseaseInfo(
    symptoms: 'Long, elliptical gray-green lesions on leaves.',
    treatment: 'Apply fungicide at early symptoms, rotate crops, use resistant hybrid varieties.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Grape___Black_rot': const _DiseaseInfo(
    symptoms: 'Small brown circular spots on leaves, black shriveled fruit (mummies).',
    treatment: 'Remove mummified fruit, apply fungicide starting at bud break, prune for airflow.',
    treatmentKeyword: 'fungicide',
    severity: 'high',
  ),
  'Grape___Esca_(Black_Measles)': const _DiseaseInfo(
    symptoms: 'Striped/tiger-pattern discoloration between leaf veins, dark spots on berries.',
    treatment: 'No full cure — prune out infected wood, avoid pruning wounds during wet weather.',
    treatmentKeyword: 'fungicide',
    severity: 'high',
  ),
  'Grape___Leaf_blight': const _DiseaseInfo(
    symptoms: 'Dark brown angular spots on leaves that may merge and cause defoliation.',
    treatment: 'Apply copper-based fungicide, remove fallen infected leaves.',
    treatmentKeyword: 'copper fungicide',
    severity: 'moderate',
  ),
  'Potato___Early_blight': const _DiseaseInfo(
    symptoms: 'Dark concentric ring spots on older leaves, yellowing tissue around lesions.',
    treatment: 'Remove affected foliage, apply fungicide, maintain balanced soil nutrition.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Potato___Late_blight': const _DiseaseInfo(
    symptoms: 'Dark, water-soaked lesions on leaves and stems, white mold in humid weather.',
    treatment: 'Apply copper-based fungicide, destroy infected tubers, ensure good drainage.',
    treatmentKeyword: 'copper fungicide',
    severity: 'high',
  ),
  'Tomato___Bacterial_spot': const _DiseaseInfo(
    symptoms: 'Small dark, greasy-looking spots on leaves and fruit.',
    treatment: 'Use copper-based bactericide, avoid overhead irrigation, remove infected plant debris.',
    treatmentKeyword: 'copper bactericide',
    severity: 'moderate',
  ),
  'Tomato___Early_blight': const _DiseaseInfo(
    symptoms: 'Brown spots with concentric rings on older leaves, yellowing around lesions.',
    treatment: 'Remove affected lower leaves, apply chlorothalonil or copper fungicide, ensure good air circulation.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Tomato___Late_blight': const _DiseaseInfo(
    symptoms: 'Dark water-soaked spots on leaves, white fungal growth on undersides, rapid spread in humid conditions.',
    treatment: 'Apply copper-based fungicide every 7 days. Remove and destroy infected leaves. Avoid overhead watering.',
    treatmentKeyword: 'copper fungicide',
    severity: 'high',
  ),
  'Tomato___Leaf_Mold': const _DiseaseInfo(
    symptoms: 'Yellow patches on upper leaf surface, olive-green mold on the underside.',
    treatment: 'Improve ventilation, reduce humidity, apply fungicide if severe.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Tomato___Septoria_leaf_spot': const _DiseaseInfo(
    symptoms: 'Small circular spots with dark borders and gray centers on lower leaves.',
    treatment: 'Remove infected leaves, apply fungicide, avoid wetting foliage when watering.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Tomato___Spider_mites': const _DiseaseInfo(
    symptoms: 'Fine yellow stippling on leaves, thin webbing visible on undersides.',
    treatment: 'Spray with insecticidal soap or neem oil; introduce predatory mites if persistent.',
    treatmentKeyword: 'neem oil',
    severity: 'moderate',
  ),
  'Tomato___Target_Spot': const _DiseaseInfo(
    symptoms: 'Brown lesions with concentric rings, similar to early blight, on leaves and fruit.',
    treatment: 'Apply fungicide, remove crop debris, rotate crops each season.',
    treatmentKeyword: 'fungicide',
    severity: 'moderate',
  ),
  'Tomato___Tomato_Yellow_Leaf_Curl_Virus': const _DiseaseInfo(
    symptoms: 'Upward curling and yellowing of leaves, stunted plant growth.',
    treatment: 'No cure — remove infected plants, control whitefly population which spreads the virus.',
    treatmentKeyword: 'insecticide',
    severity: 'high',
  ),
  'Tomato___Tomato_mosaic_virus': const _DiseaseInfo(
    symptoms: 'Mottled light and dark green pattern on leaves, distorted leaf shape.',
    treatment: 'Remove and destroy infected plants, disinfect tools, avoid tobacco product contact with plants.',
    treatmentKeyword: '',
    severity: 'high',
  ),
  // Healthy classes (Apple, Corn, Grape, Potato, Tomato) fall back to
  // the generic "no disease detected" message built above — no
  // per-crop entry needed since the message doesn't vary by crop.
};