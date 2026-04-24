import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_service.dart';

/// Firestore collection and field names for swap records.
abstract class FirestoreSwaps {
  static const String collection = 'swaps';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String initiatorUserId = 'initiatorUserId';
  static const String initiatorPostId = 'initiatorPostId';
  static const String targetUserId = 'targetUserId';
  static const String targetPostId = 'targetPostId';
  static const String createdAt = 'createdAt';
  static const String status = 'status';
}

/// A swap record between two users' posts.
class SwapRecord {
  SwapRecord({
    required this.id,
    required this.initiatorUserId,
    required this.initiatorPostId,
    required this.targetUserId,
    required this.targetPostId,
    required this.createdAt,
    this.status = FirestoreSwaps.statusInProgress,
  });

  final String id;
  final String initiatorUserId;
  final String initiatorPostId;
  final String targetUserId;
  final String targetPostId;
  final DateTime createdAt;
  final String status;

  bool get isCompleted => normalizedStatus == FirestoreSwaps.statusCompleted;
  bool get isInProgress => normalizedStatus == FirestoreSwaps.statusInProgress;
  String get normalizedStatus {
    final value = status.trim().toLowerCase();
    if (value.isEmpty) return FirestoreSwaps.statusInProgress;
    return value;
  }

  factory SwapRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SwapRecord(
      id: doc.id,
      initiatorUserId: data[FirestoreSwaps.initiatorUserId] as String? ?? '',
      initiatorPostId: data[FirestoreSwaps.initiatorPostId] as String? ?? '',
      targetUserId: data[FirestoreSwaps.targetUserId] as String? ?? '',
      targetPostId: data[FirestoreSwaps.targetPostId] as String? ?? '',
      createdAt:
          (data[FirestoreSwaps.createdAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      status:
          data[FirestoreSwaps.status] as String? ??
          FirestoreSwaps.statusInProgress,
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

  /// The current user's post id used in the swap.
  String myPostId(String currentUserId) =>
      initiatorUserId == currentUserId ? initiatorPostId : targetPostId;
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
      FirestoreSwaps.status: FirestoreSwaps.statusInProgress,
    });
    return ref.id;
  }

  static Future<void> completeSwap(String swapId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final ref = _firestore.collection(FirestoreSwaps.collection).doc(swapId);
    final doc = await ref.get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Swap record not found.');
    }

    final swap = SwapRecord.fromFirestore(doc);
    final isParticipant =
        swap.initiatorUserId == uid || swap.targetUserId == uid;
    if (!isParticipant) {
      throw Exception('You are not allowed to complete this swap.');
    }
    if (swap.isCompleted) return;

    await ref.update({FirestoreSwaps.status: FirestoreSwaps.statusCompleted});
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
    final doc = await _firestore
        .collection(FirestorePosts.collection)
        .doc(postId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return SwapPost.fromFirestore(doc);
  }
}
