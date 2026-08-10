import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'chat_service.dart';
import 'post_service.dart';

/// Firestore collection and field names for user reports / blocks.
///
/// Every report (whether a user flags a piece of content or blocks another
/// user) is written here so the developer is notified and can act on it from
/// the admin Reports screen within 24 hours, as required by App Store
/// Guideline 1.2 (User-Generated Content).
abstract class FirestoreReports {
  static const String collection = 'reports';
  static const String reporterId = 'reporterId';
  static const String reporterEmail = 'reporterEmail';
  static const String reportedUserId = 'reportedUserId';
  static const String reportedUserName = 'reportedUserName';
  static const String action = 'action'; // 'report' | 'block'
  static const String contentType =
      'contentType'; // 'post' | 'message' | 'conversation' | 'user'
  static const String contentId = 'contentId';
  static const String conversationId = 'conversationId';
  static const String contentText = 'contentText';
  static const String reason = 'reason';
  static const String details = 'details';
  static const String status = 'status'; // 'pending' | 'reviewed' | 'removed'
  static const String createdAt = 'createdAt';

  static const String actionReport = 'report';
  static const String actionBlock = 'block';

  static const String statusPending = 'pending';
  static const String statusReviewed = 'reviewed';
  static const String statusRemoved = 'removed';
}

/// Type of user-generated content being reported.
enum ReportContentType { post, message, conversation, user }

extension on ReportContentType {
  String get value => switch (this) {
    ReportContentType.post => 'post',
    ReportContentType.message => 'message',
    ReportContentType.conversation => 'conversation',
    ReportContentType.user => 'user',
  };
}

/// A moderation report row for the admin Reports screen.
class ModerationReport {
  const ModerationReport({
    required this.id,
    required this.reporterId,
    required this.reporterEmail,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.action,
    required this.contentType,
    required this.contentId,
    required this.conversationId,
    required this.contentText,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String reporterEmail;
  final String reportedUserId;
  final String reportedUserName;
  final String action;
  final String contentType;
  final String contentId;
  final String conversationId;
  final String contentText;
  final String reason;
  final String details;
  final String status;
  final DateTime? createdAt;

  bool get isBlock => action == FirestoreReports.actionBlock;
  bool get isPending => status == FirestoreReports.statusPending;

  factory ModerationReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ModerationReport(
      id: doc.id,
      reporterId: data[FirestoreReports.reporterId] as String? ?? '',
      reporterEmail: data[FirestoreReports.reporterEmail] as String? ?? '',
      reportedUserId: data[FirestoreReports.reportedUserId] as String? ?? '',
      reportedUserName:
          data[FirestoreReports.reportedUserName] as String? ?? '',
      action: data[FirestoreReports.action] as String? ??
          FirestoreReports.actionReport,
      contentType: data[FirestoreReports.contentType] as String? ?? 'user',
      contentId: data[FirestoreReports.contentId] as String? ?? '',
      conversationId: data[FirestoreReports.conversationId] as String? ?? '',
      contentText: data[FirestoreReports.contentText] as String? ?? '',
      reason: data[FirestoreReports.reason] as String? ?? '',
      details: data[FirestoreReports.details] as String? ?? '',
      status: data[FirestoreReports.status] as String? ??
          FirestoreReports.statusPending,
      createdAt: (data[FirestoreReports.createdAt] as Timestamp?)?.toDate(),
    );
  }
}

/// Handles user-generated-content moderation: flagging content, blocking
/// users (which hides their content instantly and notifies the developer),
/// and the admin-side review of the resulting reports.
class ModerationService {
  ModerationService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;
  static String get _email => _auth.currentUser?.email ?? '';

  static void _log(String op, Object e, StackTrace st) {
    developer.log(
      'ModerationService.$op failed: $e',
      name: 'ModerationService',
      stackTrace: st,
    );
  }

  /// Standard reasons a user can pick when flagging content or blocking a user.
  static const List<String> reasons = [
    'Spam or scam',
    'Harassment or bullying',
    'Hate speech or discrimination',
    'Sexual or inappropriate content',
    'Violence or threats',
    'Other objectionable content',
  ];

  /// Flags a piece of user-generated content for developer review.
  static Future<void> reportContent({
    required String reportedUserId,
    required String reportedUserName,
    required ReportContentType type,
    required String reason,
    String contentId = '',
    String conversationId = '',
    String contentText = '',
    String details = '',
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    try {
      await _firestore.collection(FirestoreReports.collection).add({
        FirestoreReports.reporterId: uid,
        FirestoreReports.reporterEmail: _email,
        FirestoreReports.reportedUserId: reportedUserId,
        FirestoreReports.reportedUserName: reportedUserName,
        FirestoreReports.action: FirestoreReports.actionReport,
        FirestoreReports.contentType: type.value,
        FirestoreReports.contentId: contentId,
        FirestoreReports.conversationId: conversationId,
        FirestoreReports.contentText: contentText,
        FirestoreReports.reason: reason,
        FirestoreReports.details: details,
        FirestoreReports.status: FirestoreReports.statusPending,
        FirestoreReports.createdAt: FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      _log('reportContent', e, st);
      rethrow;
    }
  }

  /// Blocks [blockedUserId]: hides their content from this user's feeds
  /// immediately and notifies the developer with a report entry so the
  /// offending user/content can be reviewed within 24 hours.
  static Future<void> blockUser({
    required String blockedUserId,
    required String blockedUserName,
    String reason = '',
    String contentText = '',
    ReportContentType contentType = ReportContentType.user,
    String contentId = '',
    String conversationId = '',
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    if (uid == blockedUserId) throw Exception('You cannot block yourself');
    try {
      // 1. Record the block on the current user's profile so their feeds
      //    filter out the blocked user instantly.
      await _firestore
          .collection(FirestoreUsers.collection)
          .doc(uid)
          .set({
            FirestoreUsers.blockedUserIds: FieldValue.arrayUnion([
              blockedUserId,
            ]),
          }, SetOptions(merge: true));

      // 2. Notify the developer for review.
      await _firestore.collection(FirestoreReports.collection).add({
        FirestoreReports.reporterId: uid,
        FirestoreReports.reporterEmail: _email,
        FirestoreReports.reportedUserId: blockedUserId,
        FirestoreReports.reportedUserName: blockedUserName,
        FirestoreReports.action: FirestoreReports.actionBlock,
        FirestoreReports.contentType: contentType.value,
        FirestoreReports.contentId: contentId,
        FirestoreReports.conversationId: conversationId,
        FirestoreReports.contentText: contentText,
        FirestoreReports.reason: reason.isEmpty ? 'User blocked' : reason,
        FirestoreReports.details: '',
        FirestoreReports.status: FirestoreReports.statusPending,
        FirestoreReports.createdAt: FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      _log('blockUser', e, st);
      rethrow;
    }
  }

  /// Removes a user from the current user's block list.
  static Future<void> unblockUser(String blockedUserId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    try {
      await _firestore.collection(FirestoreUsers.collection).doc(uid).set({
        FirestoreUsers.blockedUserIds: FieldValue.arrayRemove([blockedUserId]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _log('unblockUser', e, st);
      rethrow;
    }
  }

  static Set<String> _blockedFromData(Map<String, dynamic>? data) {
    final raw = data?[FirestoreUsers.blockedUserIds];
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return <String>{};
  }

  /// Live set of user ids the current user has blocked. Emits an empty set
  /// when signed out.
  static Stream<Set<String>> streamBlockedUserIds() {
    final uid = _uid;
    if (uid == null) return Stream.value(<String>{});
    return _firestore
        .collection(FirestoreUsers.collection)
        .doc(uid)
        .snapshots()
        .map((doc) => _blockedFromData(doc.data()));
  }

  /// One-shot read of the current user's blocked ids.
  static Future<Set<String>> getBlockedUserIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    try {
      final doc = await _firestore
          .collection(FirestoreUsers.collection)
          .doc(uid)
          .get();
      return _blockedFromData(doc.data());
    } catch (e, st) {
      _log('getBlockedUserIds', e, st);
      return <String>{};
    }
  }

  /// Resolves a set of user ids to public display names (username, falling back
  /// to full name) for the Blocked Users screen.
  static Future<Map<String, String>> fetchDisplayNames(
    Iterable<String> ids,
  ) async {
    final result = <String, String>{};
    for (final id in ids) {
      try {
        final doc = await _firestore
            .collection(FirestoreUsers.collection)
            .doc(id)
            .get();
        final data = doc.data();
        final username = data?[FirestoreUsers.username] as String? ?? '';
        final fullName = data?[FirestoreUsers.fullName] as String? ?? '';
        result[id] = username.isNotEmpty
            ? username
            : (fullName.isNotEmpty ? fullName : 'User');
      } catch (_) {
        result[id] = 'User';
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Admin-side moderation
  // ---------------------------------------------------------------------------

  /// Live stream of all reports, newest first (admin Reports screen).
  static Stream<List<ModerationReport>> streamReports() {
    return _firestore
        .collection(FirestoreReports.collection)
        .orderBy(FirestoreReports.createdAt, descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(ModerationReport.fromFirestore).toList(),
        );
  }

  static Future<void> updateReportStatus(String reportId, String status) {
    return _firestore
        .collection(FirestoreReports.collection)
        .doc(reportId)
        .update({FirestoreReports.status: status});
  }

  /// Removes the content a report refers to (a post or a whole conversation)
  /// and marks the report as removed.
  static Future<void> removeReportedContent(ModerationReport report) async {
    try {
      if (report.contentType == ReportContentType.post.value &&
          report.contentId.isNotEmpty) {
        await _firestore
            .collection(FirestorePosts.collection)
            .doc(report.contentId)
            .delete();
      } else if ((report.contentType == ReportContentType.conversation.value ||
              report.contentType == ReportContentType.message.value) &&
          report.conversationId.isNotEmpty) {
        await _deleteConversation(report.conversationId);
      }
      await updateReportStatus(report.id, FirestoreReports.statusRemoved);
    } catch (e, st) {
      _log('removeReportedContent', e, st);
      rethrow;
    }
  }

  static Future<void> _deleteConversation(String conversationId) async {
    final convRef = _firestore
        .collection(FirestoreConversations.collection)
        .doc(conversationId);
    final messages = await convRef
        .collection(FirestoreMessages.subcollection)
        .get();
    for (final chunk in _chunk(messages.docs, 400)) {
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await convRef.delete();
  }

  static Iterable<List<T>> _chunk<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}
