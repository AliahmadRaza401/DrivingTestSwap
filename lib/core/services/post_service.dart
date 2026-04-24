import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firestore collection and field names for swap posts.
abstract class FirestorePosts {
  static const String collection = 'swap_posts';
  static const String userId = 'userId';
  static const String testCentre = 'testCentre';
  static const String testCentreLat = 'testCentreLat';
  static const String testCentreLng = 'testCentreLng';
  static const String date = 'date';
  static const String time = 'time';
  static const String lookingFor = 'lookingFor';
  static const String preferredArea = 'preferredArea';
  static const String notes = 'notes';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String creatorName = 'creatorName';
  static const String creatorInitials = 'creatorInitials';
}

/// Swap post model for noticeboard and my posts.
class SwapPost {
  SwapPost({
    required this.id,
    required this.userId,
    required this.testCentre,
    this.testCentreLat,
    this.testCentreLng,
    required this.date,
    required this.time,
    required this.lookingFor,
    this.preferredArea = '',
    this.notes = '',
    required this.createdAt,
    DateTime? updatedAt,
    required this.creatorName,
    required this.creatorInitials,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String userId;
  final String testCentre;
  final double? testCentreLat;
  final double? testCentreLng;
  final String date;
  final String time;
  final String lookingFor;
  final String preferredArea;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String creatorName;
  final String creatorInitials;

  bool get hasTestCentreLocation =>
      testCentreLat != null && testCentreLng != null;

  factory SwapPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SwapPost(
      id: doc.id,
      userId: data[FirestorePosts.userId] as String? ?? '',
      testCentre: data[FirestorePosts.testCentre] as String? ?? '',
      testCentreLat: (data[FirestorePosts.testCentreLat] as num?)?.toDouble(),
      testCentreLng: (data[FirestorePosts.testCentreLng] as num?)?.toDouble(),
      date: data[FirestorePosts.date] as String? ?? '',
      time: data[FirestorePosts.time] as String? ?? '',
      lookingFor: data[FirestorePosts.lookingFor] as String? ?? '',
      preferredArea: data[FirestorePosts.preferredArea] as String? ?? '',
      notes: data[FirestorePosts.notes] as String? ?? '',
      createdAt:
          (data[FirestorePosts.createdAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (data[FirestorePosts.updatedAt] as Timestamp?)?.toDate(),
      creatorName: data[FirestorePosts.creatorName] as String? ?? '',
      creatorInitials: data[FirestorePosts.creatorInitials] as String? ?? '?',
    );
  }

  Map<String, dynamic> toMap() => {
    FirestorePosts.userId: userId,
    FirestorePosts.testCentre: testCentre,
    FirestorePosts.testCentreLat: testCentreLat,
    FirestorePosts.testCentreLng: testCentreLng,
    FirestorePosts.date: date,
    FirestorePosts.time: time,
    FirestorePosts.lookingFor: lookingFor,
    FirestorePosts.preferredArea: preferredArea,
    FirestorePosts.notes: notes,
    FirestorePosts.createdAt: Timestamp.fromDate(createdAt),
    FirestorePosts.updatedAt: Timestamp.fromDate(updatedAt),
    FirestorePosts.creatorName: creatorName,
    FirestorePosts.creatorInitials: creatorInitials,
  };
}

class PostService {
  PostService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static void _logPostError(String operation, Object e, StackTrace st) {
    developer.log(
      'PostService.$operation failed: $e',
      name: 'PostService',
      stackTrace: st,
    );
    if (kDebugMode) {
      debugPrint('[PostService.$operation] ERROR: $e');
      debugPrint('[PostService.$operation] StackTrace: $st');
    }
  }

  /// Returns a short user-friendly message for Firestore errors (e.g. index required or building).
  static String userFriendlyPostError(Object e) {
    final s = e.toString();
    if (s.contains('failed-precondition') && s.contains('index')) {
      if (s.contains('currently building')) {
        return 'Index is still building. Wait a few minutes and try again, or tap "Check status" below.';
      }
      return 'Database index required. Tap "Create index" below to open Firebase Console and create it.';
    }
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s;
  }

  /// True when the error says the index is building (not yet ready).
  static bool isIndexBuildingError(Object e) {
    return e.toString().contains('currently building');
  }

  /// Extracts the Firebase Console index URL from the Firestore error message, if present.
  static String? getIndexCreationUrlFromError(Object e) {
    final s = e.toString();
    final match = RegExp(
      r'https://console\.firebase\.google\.com[^\s\)\]]+',
    ).firstMatch(s);
    return match?.group(0);
  }

  /// Create a new swap post. Uses current user id and provided creator name/initials.
  /// Throws on failure (no user, or Firestore error).
  static Future<String> createPost({
    required String testCentre,
    required double testCentreLat,
    required double testCentreLng,
    required String date,
    required String time,
    required String lookingFor,
    String preferredArea = '',
    String notes = '',
    required String creatorName,
    required String creatorInitials,
  }) async {
    final uid = _uid;
    if (uid == null) {
      const msg = 'Not signed in. Please log in to post.';
      _logPostError('createPost', msg, StackTrace.current);
      throw Exception(msg);
    }
    try {
      final now = DateTime.now();
      final ref = await _firestore.collection(FirestorePosts.collection).add({
        FirestorePosts.userId: uid,
        FirestorePosts.testCentre: testCentre,
        FirestorePosts.testCentreLat: testCentreLat,
        FirestorePosts.testCentreLng: testCentreLng,
        FirestorePosts.date: date,
        FirestorePosts.time: time,
        FirestorePosts.lookingFor: lookingFor,
        FirestorePosts.preferredArea: preferredArea,
        FirestorePosts.notes: notes,
        FirestorePosts.createdAt: Timestamp.fromDate(now),
        FirestorePosts.updatedAt: Timestamp.fromDate(now),
        FirestorePosts.creatorName: creatorName,
        FirestorePosts.creatorInitials: creatorInitials,
      });
      return ref.id;
    } catch (e, st) {
      _logPostError('createPost', e, st);
      rethrow;
    }
  }

  /// Stream of current user's posts (for My Posts page).
  static Stream<List<SwapPost>> streamMyPosts() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection(FirestorePosts.collection)
        .where(FirestorePosts.userId, isEqualTo: uid)
        .orderBy(FirestorePosts.createdAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SwapPost.fromFirestore(d)).toList())
        .handleError((e, st) {
          _logPostError('streamMyPosts', e, st);
          throw e;
        });
  }

  /// Stream of other users' posts (exclude current user) for Noticeboard.
  static Stream<List<SwapPost>> streamOtherUsersPosts() {
    final uid = _uid;
    return _firestore
        .collection(FirestorePosts.collection)
        .orderBy(FirestorePosts.createdAt, descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => SwapPost.fromFirestore(d))
              .where((p) => p.userId != uid)
              .toList();
        })
        .handleError((e, st) {
          _logPostError('streamOtherUsersPosts', e, st);
          throw e;
        });
  }

  /// Get a single post by id (for edit).
  static Future<SwapPost?> getPost(String postId) async {
    final doc = await _firestore
        .collection(FirestorePosts.collection)
        .doc(postId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return SwapPost.fromFirestore(doc);
  }

  /// Update an existing post. Throws if not owner or Firestore error.
  static Future<void> updatePost({
    required String postId,
    required String testCentre,
    required double testCentreLat,
    required double testCentreLng,
    required String date,
    required String time,
    required String lookingFor,
    String preferredArea = '',
    String notes = '',
  }) async {
    final uid = _uid;
    if (uid == null) {
      const msg = 'Not signed in. Please log in to update.';
      _logPostError('updatePost', msg, StackTrace.current);
      throw Exception(msg);
    }
    try {
      final ref = _firestore.collection(FirestorePosts.collection).doc(postId);
      final doc = await ref.get();
      if (!doc.exists ||
          (doc.data()?[FirestorePosts.userId] as String?) != uid) {
        final msg =
            'Post not found or you do not have permission to update it.';
        _logPostError('updatePost', msg, StackTrace.current);
        throw Exception(msg);
      }
      await ref.update({
        FirestorePosts.testCentre: testCentre,
        FirestorePosts.testCentreLat: testCentreLat,
        FirestorePosts.testCentreLng: testCentreLng,
        FirestorePosts.date: date,
        FirestorePosts.time: time,
        FirestorePosts.lookingFor: lookingFor,
        FirestorePosts.preferredArea: preferredArea,
        FirestorePosts.notes: notes,
        FirestorePosts.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      _logPostError('updatePost', e, st);
      rethrow;
    }
  }

  /// Delete a post. Throws if not owner or Firestore error.
  static Future<void> deletePost(String postId) async {
    final uid = _uid;
    if (uid == null) {
      const msg = 'Not signed in. Please log in to delete.';
      _logPostError('deletePost', msg, StackTrace.current);
      throw Exception(msg);
    }
    try {
      final doc = await _firestore
          .collection(FirestorePosts.collection)
          .doc(postId)
          .get();
      if (!doc.exists ||
          (doc.data()?[FirestorePosts.userId] as String?) != uid) {
        final msg =
            'Post not found or you do not have permission to delete it.';
        _logPostError('deletePost', msg, StackTrace.current);
        throw Exception(msg);
      }
      await _firestore
          .collection(FirestorePosts.collection)
          .doc(postId)
          .delete();
    } catch (e, st) {
      _logPostError('deletePost', e, st);
      rethrow;
    }
  }
}
