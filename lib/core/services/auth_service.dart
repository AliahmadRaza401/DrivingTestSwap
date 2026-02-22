import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_preferences_service.dart';

/// Firestore collection and field names for user profile.
abstract class FirestoreUsers {
  static const String collection = 'users';
  static const String email = 'email';
  static const String fullName = 'fullName';
  static const String dateOfBirth = 'dateOfBirth';
  static const String createdAt = 'createdAt';
  // Subscription (set after successful payment)
  static const String subscriptionPlanId = 'subscriptionPlanId';
  static const String subscriptionPlanTitle = 'subscriptionPlanTitle';
  static const String subscriptionPrice = 'subscriptionPrice';
  static const String subscriptionPeriod = 'subscriptionPeriod';
  static const String subscribedAt = 'subscribedAt';
  static const String subscriptionExpiresAt = 'subscriptionExpiresAt';
}

/// Current subscription status for display (plan name and expiry).
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.planTitle,
    required this.planId,
    this.expiresAt,
  });
  final String planTitle;
  final String planId;
  final DateTime? expiresAt;
}

/// Wrapper for Firebase Auth and user profile in Firestore.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static const int _firestoreRetryCount = 3;
  static const Duration _firestoreRetryDelay = Duration(seconds: 2);

  /// Create account with email and password, then save profile to Firestore.
  /// Returns null on success, or a user-friendly error message on failure.
  /// If Firestore fails after retries, the Auth user is removed so the user can retry signup.
  static Future<String?> signUp({
    required String email,
    required String password,
    String? fullName,
    String? dateOfBirth,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        try {
          await _saveUserToFirestoreWithRetry(
            uid: user.uid,
            email: email.trim(),
            fullName: fullName?.trim(),
            dateOfBirth: dateOfBirth?.trim(),
          );
        } on FirebaseException catch (e, st) {
          _logFirebaseError('SignUp Firestore', e, st);
          await _rollbackNewAuthUser();
          return _isConnectionError(e.message)
              ? _connectionErrorMessage
              : (e.message ?? 'Failed to save profile. Please try again.');
        } on TimeoutException catch (e, st) {
          _logError('SignUp Firestore Timeout', e, st);
          await _rollbackNewAuthUser();
          return _connectionErrorMessage;
        } catch (e, st) {
          _logError('SignUp Firestore', e, st);
          await _rollbackNewAuthUser();
          return _isConnectionError(e.toString())
              ? _connectionErrorMessage
              : 'Failed to save profile. Please try again.';
        }
      }
      return null;
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('SignUp', e, st);
      return _signUpErrorMessage(e);
    } on FirebaseException catch (e, st) {
      _logFirebaseError('SignUp Firestore', e, st);
      return _isConnectionError(e.message)
          ? _connectionErrorMessage
          : (e.message ?? 'Failed to save profile. Please try again.');
    } on TimeoutException catch (e, st) {
      _logError('SignUp Timeout', e, st);
      return _connectionErrorMessage;
    } catch (e, st) {
      _logError('SignUp', e, st);
      return _isConnectionError(e.toString())
          ? _connectionErrorMessage
          : 'Something went wrong. Please try again.';
    }
  }

  /// Removes the current Auth user so signup can be retried (used when Firestore save fails).
  static Future<void> _rollbackNewAuthUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      if (!kReleaseMode) debugPrint('[SignUp] Rollback delete user failed: $e');
    }
  }

  /// Saves signup profile data to Firestore with retries for connection errors.
  static Future<void> _saveUserToFirestoreWithRetry({
    required String uid,
    required String email,
    String? fullName,
    String? dateOfBirth,
  }) async {
    var lastException;
    for (var attempt = 1; attempt <= _firestoreRetryCount; attempt++) {
      try {
        await _firestore.collection(FirestoreUsers.collection).doc(uid).set({
          FirestoreUsers.email: email,
          FirestoreUsers.fullName: fullName ?? '',
          FirestoreUsers.dateOfBirth: dateOfBirth ?? '',
          FirestoreUsers.createdAt: FieldValue.serverTimestamp(),
        });
        return;
      } on FirebaseException catch (e) {
        lastException = e;
        if (!_isConnectionError(e.message) || attempt == _firestoreRetryCount) rethrow;
        if (!kReleaseMode) debugPrint('[SignUp] Firestore attempt $attempt failed, retrying: ${e.message}');
        await Future.delayed(_firestoreRetryDelay);
      } on TimeoutException catch (e) {
        lastException = e;
        if (attempt == _firestoreRetryCount) rethrow;
        if (!kReleaseMode) debugPrint('[SignUp] Firestore attempt $attempt timeout, retrying');
        await Future.delayed(_firestoreRetryDelay);
      }
    }
    if (lastException != null) throw lastException;
  }

  /// Sign in with email and password.
  /// Returns null on success, or a user-friendly error message on failure.
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('SignIn', e, st);
      return _signInErrorMessage(e);
    } on FirebaseException catch (e, st) {
      _logFirebaseError('SignIn Firestore', e, st);
      return _isConnectionError(e.message) ? _connectionErrorMessage : (e.message ?? 'Something went wrong. Please try again.');
    } on TimeoutException catch (e, st) {
      _logError('SignIn Timeout', e, st);
      return _connectionErrorMessage;
    } catch (e, st) {
      _logError('SignIn', e, st);
      return _isConnectionError(e.toString()) ? _connectionErrorMessage : 'Something went wrong. Please try again.';
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns true if the current user has an active subscription (has completed at least one plan purchase).
  static Future<bool> hasActiveSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore
          .collection(FirestoreUsers.collection)
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data() == null) return false;
      final planId = doc.data()?[FirestoreUsers.subscriptionPlanId] as String?;
      return planId != null && planId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Saves subscription details to the current user's Firestore profile after successful payment.
  static Future<void> saveUserSubscription({
    required String planId,
    required String planTitle,
    required String price,
    required String period,
    DateTime? expiresAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = <String, dynamic>{
      FirestoreUsers.subscriptionPlanId: planId,
      FirestoreUsers.subscriptionPlanTitle: planTitle,
      FirestoreUsers.subscriptionPrice: price,
      FirestoreUsers.subscriptionPeriod: period,
      FirestoreUsers.subscribedAt: FieldValue.serverTimestamp(),
    };
    if (expiresAt != null) {
      data[FirestoreUsers.subscriptionExpiresAt] = Timestamp.fromDate(expiresAt);
    }
    await _firestore.collection(FirestoreUsers.collection).doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Fetches current subscription status (plan name and expiry) for display. Returns null if no subscription.
  static Future<SubscriptionStatus?> getSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore
          .collection(FirestoreUsers.collection)
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      final planId = data[FirestoreUsers.subscriptionPlanId] as String?;
      final planTitle = data[FirestoreUsers.subscriptionPlanTitle] as String?;
      if (planId == null || planId.isEmpty) return null;
      DateTime? expiresAt;
      final expires = data[FirestoreUsers.subscriptionExpiresAt];
      if (expires is Timestamp) expiresAt = expires.toDate();
      return SubscriptionStatus(
        planTitle: planTitle ?? planId,
        planId: planId,
        expiresAt: expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Updates the current user's profile in Firestore (fullName, dateOfBirth). Also updates local prefs.
  /// Returns null on success, or a user-friendly error message.
  static Future<String?> updateProfile({String? fullName, String? dateOfBirth}) async {
    final user = _auth.currentUser;
    if (user == null) return 'Not signed in.';
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data[FirestoreUsers.fullName] = fullName.trim();
      if (dateOfBirth != null) data[FirestoreUsers.dateOfBirth] = dateOfBirth.trim();
      if (data.isEmpty) return null;
      await _firestore.collection(FirestoreUsers.collection).doc(user.uid).set(data, SetOptions(merge: true));
      await UserPreferencesService.updateProfileData(fullName: fullName?.trim(), dateOfBirth: dateOfBirth?.trim());
      return null;
    } on FirebaseException catch (e, st) {
      _logFirebaseError('updateProfile', e, st);
      return _isConnectionError(e.message) ? _connectionErrorMessage : (e.message ?? 'Failed to update profile.');
    } catch (e, st) {
      _logError('updateProfile', e, st);
      return 'Failed to update profile. Please try again.';
    }
  }

  /// Changes the current user's password. Requires current password for re-authentication.
  /// Returns null on success, or a user-friendly error message.
  static Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Not signed in.';
    if (user.email == null || user.email!.isEmpty) return 'Email not set. Cannot change password.';
    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e, st) {
      _logFirebaseAuthError('updatePassword', e, st);
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Current password is incorrect.';
      }
      if (e.code == 'weak-password') return 'New password is too weak. Use at least 6 characters.';
      return e.message ?? 'Failed to change password.';
    } catch (e, st) {
      _logError('updatePassword', e, st);
      return 'Failed to change password. Please try again.';
    }
  }

  /// Fetches the current user's profile from Firestore (uid, email, fullName, dateOfBirth).
  /// Returns null if not signed in or document is missing.
  static Future<Map<String, String>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore
          .collection(FirestoreUsers.collection)
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return {
        'uid': user.uid,
        'email': (data[FirestoreUsers.email] as String?) ?? user.email ?? '',
        'fullName': (data[FirestoreUsers.fullName] as String?) ?? '',
        'dateOfBirth': (data[FirestoreUsers.dateOfBirth] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static const String _connectionErrorMessage =
      'Unable to connect. Please check your internet connection and try again.';

  static void _logFirebaseAuthError(String context, FirebaseAuthException e, StackTrace st) {
    if (kReleaseMode) return;
    debugPrint('[$context] FirebaseAuthException: code=${e.code}, message=${e.message}, plugin=${e.plugin}');
    debugPrint('[$context] StackTrace: $st');
  }

  static void _logFirebaseError(String context, FirebaseException e, StackTrace st) {
    if (kReleaseMode) return;
    debugPrint('[$context] FirebaseException: code=${e.code}, message=${e.message}, plugin=${e.plugin}');
    debugPrint('[$context] StackTrace: $st');
  }

  static void _logError(String context, Object e, StackTrace st) {
    if (kReleaseMode) return;
    debugPrint('[$context] Error: $e');
    debugPrint('[$context] StackTrace: $st');
  }

  static bool _isConnectionError(String? message) {
    if (message == null || message.isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('unable to establish') ||
        lower.contains('socket') ||
        lower.contains('timed out') ||
        lower.contains('failed to host');
  }

  /// User-friendly messages for signup (createUserWithEmailAndPassword).
  static String _signUpErrorMessage(FirebaseAuthException e) {
    if (_isConnectionError(e.message)) return _connectionErrorMessage;
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email already exists. Please log in or use a different email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-up is not available. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid details. Please check your email and password.';
      case 'requires-recent-login':
        return 'Please log out and try again.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Something went wrong. Please try again.';
    }
  }

  /// User-friendly messages for login (signInWithEmailAndPassword).
  static String _signInErrorMessage(FirebaseAuthException e) {
    if (_isConnectionError(e.message)) return _connectionErrorMessage;
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Credentials not correct. Please check your email and password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not available. Please contact support.';
      case 'requires-recent-login':
        return 'Please log out and try again.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Credentials not correct. Please check your email and password.';
    }
  }
}
