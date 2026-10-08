import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Handles all authentication logic for AgriVision AI.
/// Wraps Firebase Auth (email/password) and creates a matching
/// user profile document in Firestore on registration.
///
/// Note on error handling: this service has no BuildContext, so it
/// cannot produce localized text itself. On failure it returns a
/// translation *key* (AuthResult.errorKey) rather than a final English
/// string — the UI layer looks that key up via context.tr(...) at
/// display time. See LocalizationService's 'auth_error_*' keys.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Stream of auth state changes — use this to drive routing
  /// (e.g. via a StreamBuilder wrapping the app's root widget).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user, if any.
  User? get currentUser => _auth.currentUser;

  /// Registers a new farmer account with email/password and
  /// creates a corresponding document in the `users` collection.
  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        return AuthResult.failure('auth_error_registration_failed');
      }

      // Update display name on the Firebase Auth profile.
      await credential.user?.updateDisplayName(name.trim());

      // Create the matching user profile document (see section 15,
      // `users` collection in the technical documentation).
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'farms': <String>[],
      });

      await _onAuthSuccess();

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('auth_error_generic');
    }
  }

  /// Signs in an existing farmer with email/password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _onAuthSuccess();

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('auth_error_generic');
    }
  }

  /// Sends a password-reset email.
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    }
  }

  /// Re-authenticates with [currentPassword], then sends a verification
  /// link to [newEmail]. The email on the account only actually changes
  /// once the farmer clicks that link — Firebase does not allow an
  /// immediate swap for security reasons.
  Future<AuthResult> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return AuthResult.failure('auth_error_generic');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('auth_error_generic');
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Runs after any successful register/sign-in. Re-schedules the daily
  /// reminder so users get it without ever having to open Settings,
  /// as long as they haven't explicitly turned notifications off there.
  /// Also re-registers the FCM token now that we have a signed-in uid
  /// (NotificationService.initialize() may have run before login and
  /// skipped that step).
  Future<void> _onAuthSuccess() async {
    try {
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      if (notificationsEnabled) {
        await _notificationService.scheduleDailyReminder();
      }
    } catch (e) {
      // Non-fatal — login/registration should never fail because of a
      // notification scheduling hiccup.
    }
  }

  /// Converts Firebase's error codes into a translation key the UI
  /// can look up in the farmer's chosen language.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'auth_error_email_in_use';
      case 'invalid-email':
        return 'auth_error_invalid_email';
      case 'weak-password':
        return 'auth_error_weak_password';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_error_invalid_credential';
      case 'too-many-requests':
        return 'auth_error_too_many_requests';
      case 'network-request-failed':
        return 'auth_error_network';
      case 'requires-recent-login':
        return 'auth_error_requires_recent_login';
      default:
        // e.message is Firebase's raw (English-only) message and can't
        // be localized, so unmapped codes fall back to a generic key.
        return 'auth_error_generic';
    }
  }
}

/// Simple result wrapper so UI code never has to catch exceptions directly.
class AuthResult {
  final bool isSuccess;
  final User? user;

  /// A translation key (e.g. 'auth_error_invalid_credential'), not a
  /// display string. Callers should render it via context.tr(errorKey!).
  final String? errorKey;

  AuthResult._(this.isSuccess, this.user, this.errorKey);

  factory AuthResult.success(User? user) => AuthResult._(true, user, null);
  factory AuthResult.failure(String errorKey) =>
      AuthResult._(false, null, errorKey);
}