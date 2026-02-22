import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_service.dart';

/// Firestore collection and field names for swap records.
abstract class FirestoreSwaps {
  static const String collection = 'swaps';
  static const String initiatorUserId = 'initiatorUserId';
  static const String initiatorPostId = 'initiatorPostId';
  static const String targetUserId = 'targetUserId';
  static const String targetPostId = 'targetPostId';
  static const String createdAt = 'createdAt';
  static const String status = 'status';
}

/// A completed swap between two users' posts.
class SwapRecord {
  SwapRecord({
    required this.id,
    required this.initiatorUserId,
    required this.initiatorPostId,
    required this.targetUserId,
    required this.targetPostId,
    required this.createdAt,
    this.status = 'completed',
  });

  final String id;
  final String initiatorUserId;
  final String initiatorPostId;
  final String targetUserId;
  final String targetPostId;
  final DateTime createdAt;
  final String status;

  factory SwapRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SwapRecord(
      id: doc.id,
      initiatorUserId: data[FirestoreSwaps.initiatorUserId] as String? ?? '',
      initiatorPostId: data[FirestoreSwaps.initiatorPostId] as String? ?? '',
      targetUserId: data[FirestoreSwaps.targetUserId] as String? ?? '',
      targetPostId: data[FirestoreSwaps.targetPostId] as String? ?? '',
      createdAt: (data[FirestoreSwaps.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data[FirestoreSwaps.status] as String? ?? 'completed',
    );
  }

  /// True if the current user is the initiator of this swap.
  bool isInitiator(String currentUserId) => initiatorUserId == currentUserId;
  /// The "other" user's id (the one we swapped with).
  String otherUserId(String currentUserId) =>
      initiatorUserId == currentUserId ? targetUserId : initiatorUserId;
  /// The post id that belongs to the other user (the slot we got).
  String otherPostId(String currentUserId) =>
      initiatorUserId == currentUserId ? targetPostId : initiatorPostId;
}

class SwapService {
  SwapService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? get _uid => _auth.currentUser?.uid;

  /// Create a swap record when user A initiates swap with user B's post (using A's selected post).
  static Future<String> createSwap({
    required String myPostId,
    required String targetUserId,
    required String targetPostId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final ref = await _firestore.collection(FirestoreSwaps.collection).add({
      FirestoreSwaps.initiatorUserId: uid,
      FirestoreSwaps.initiatorPostId: myPostId,
      FirestoreSwaps.targetUserId: targetUserId,
      FirestoreSwaps.targetPostId: targetPostId,
      FirestoreSwaps.createdAt: FieldValue.serverTimestamp(),
      FirestoreSwaps.status: 'completed',
    });
    return ref.id;
  }

  /// Stream of swap records where current user is initiator or target.
  static Stream<List<SwapRecord>> streamMySwaps() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection(FirestoreSwaps.collection)
        .orderBy(FirestoreSwaps.createdAt, descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => SwapRecord.fromFirestore(d))
          .where((s) => s.initiatorUserId == uid || s.targetUserId == uid)
          .toList();
    });
  }

  /// Get the other user's post (the slot we got from swap) for display.
  static Future<SwapPost?> getPostById(String postId) async {
    final doc = await _firestore.collection(FirestorePosts.collection).doc(postId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SwapPost.fromFirestore(doc);
  }
}
