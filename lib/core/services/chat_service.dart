import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_preferences_service.dart';

abstract class FirestoreConversations {
  static const String collection = 'conversations';
  static const String participantIds = 'participantIds';
  static const String user1Id = 'user1Id';
  static const String user2Id = 'user2Id';
  static const String user1DisplayName = 'user1DisplayName';
  static const String user1Initials = 'user1Initials';
  static const String user2DisplayName = 'user2DisplayName';
  static const String user2Initials = 'user2Initials';
  static const String lastMessageAt = 'lastMessageAt';
  static const String lastMessageText = 'lastMessageText';
  static const String lastMessageSenderId = 'lastMessageSenderId';
  static const String createdAt = 'createdAt';
}

abstract class FirestoreMessages {
  static const String subcollection = 'messages';
  static const String senderId = 'senderId';
  static const String text = 'text';
  static const String createdAt = 'createdAt';
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ChatMessage(
      id: doc.id,
      senderId: data[FirestoreMessages.senderId] as String? ?? '',
      text: data[FirestoreMessages.text] as String? ?? '',
      createdAt:
          (data[FirestoreMessages.createdAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}

class ConversationSummary {
  ConversationSummary({
    required this.conversationId,
    required this.otherUserId,
    required this.otherDisplayName,
    required this.otherInitials,
    this.lastMessageText = '',
    this.lastMessageAt,
  });

  final String conversationId;
  final String otherUserId;
  final String otherDisplayName;
  final String otherInitials;
  final String lastMessageText;
  final DateTime? lastMessageAt;
}

class AdminConversationSummary {
  AdminConversationSummary({
    required this.conversationId,
    required this.user1Id,
    required this.user1DisplayName,
    required this.user1Initials,
    required this.user2Id,
    required this.user2DisplayName,
    required this.user2Initials,
    this.lastMessageText = '',
    this.lastMessageAt,
  });

  final String conversationId;
  final String user1Id;
  final String user1DisplayName;
  final String user1Initials;
  final String user2Id;
  final String user2DisplayName;
  final String user2Initials;
  final String lastMessageText;
  final DateTime? lastMessageAt;
}

class ChatService {
  ChatService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? get _uid => _auth.currentUser?.uid;

  /// Conversation doc id is sorted [uid1, uid2] so both users get the same id.
  static String _conversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return list.join('_');
  }

  /// Get or create a conversation between current user and [otherUserId]. Uses [otherDisplayName] and [otherInitials] for the other user when creating.
  static Future<String> getOrCreateConversation({
    required String otherUserId,
    required String otherDisplayName,
    required String otherInitials,
  }) async {
    final myUid = _uid;
    if (myUid == null) throw Exception('Not signed in');
    if (myUid == otherUserId) throw Exception('Cannot chat with yourself');
    final cid = _conversationId(myUid, otherUserId);
    final ref = _firestore
        .collection(FirestoreConversations.collection)
        .doc(cid);
    final doc = await ref.get();
    if (doc.exists) return cid;
    final myName = await UserPreferencesService.fullName ?? 'You';
    final myInitials = _initialsFromName(myName);
    final u1 = myUid.compareTo(otherUserId) < 0 ? myUid : otherUserId;
    final u2 = myUid.compareTo(otherUserId) < 0 ? otherUserId : myUid;
    final name1 = myUid.compareTo(otherUserId) < 0 ? myName : otherDisplayName;
    final name2 = myUid.compareTo(otherUserId) < 0 ? otherDisplayName : myName;
    final in1 = myUid.compareTo(otherUserId) < 0 ? myInitials : otherInitials;
    final in2 = myUid.compareTo(otherUserId) < 0 ? otherInitials : myInitials;
    final now = FieldValue.serverTimestamp();
    await ref.set({
      FirestoreConversations.participantIds: [u1, u2],
      FirestoreConversations.user1Id: u1,
      FirestoreConversations.user2Id: u2,
      FirestoreConversations.user1DisplayName: name1,
      FirestoreConversations.user1Initials: in1,
      FirestoreConversations.user2DisplayName: name2,
      FirestoreConversations.user2Initials: in2,
      FirestoreConversations.lastMessageAt: now,
      FirestoreConversations.lastMessageText: '',
      FirestoreConversations.lastMessageSenderId: '',
      FirestoreConversations.createdAt: now,
    });
    return cid;
  }

  static String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return (parts.first[0].toUpperCase() + parts[1][0].toUpperCase());
  }

  static Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _firestore
        .collection(FirestoreConversations.collection)
        .doc(conversationId)
        .collection(FirestoreMessages.subcollection)
        .orderBy(FirestoreMessages.createdAt, descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList(),
        );
  }

  static Future<void> sendMessage(String conversationId, String text) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final messagesRef = _firestore
        .collection(FirestoreConversations.collection)
        .doc(conversationId)
        .collection(FirestoreMessages.subcollection);
    final convRef = _firestore
        .collection(FirestoreConversations.collection)
        .doc(conversationId);
    await _firestore.runTransaction((tx) async {
      tx.set(messagesRef.doc(), {
        FirestoreMessages.senderId: uid,
        FirestoreMessages.text: trimmed,
        FirestoreMessages.createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(convRef, {
        FirestoreConversations.lastMessageAt: FieldValue.serverTimestamp(),
        FirestoreConversations.lastMessageText: trimmed,
        FirestoreConversations.lastMessageSenderId: uid,
      });
    });
  }

  /// Returns a short user-friendly message for Firestore errors (e.g. index required or building).
  static String userFriendlyChatError(Object e) {
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

  /// Stream of conversations for the current user (for Messages list).
  static Stream<List<ConversationSummary>> streamMyConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection(FirestoreConversations.collection)
        .where(FirestoreConversations.participantIds, arrayContains: uid)
        .orderBy(FirestoreConversations.lastMessageAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _docToSummary(d, uid)).toList());
  }

  static Stream<List<AdminConversationSummary>> streamAllConversations() {
    return _firestore
        .collection(FirestoreConversations.collection)
        .orderBy(FirestoreConversations.lastMessageAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _docToAdminSummary(d)).toList());
  }

  static ConversationSummary _docToSummary(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String myUid,
  ) {
    final data = doc.data()!;
    final id = doc.id;
    final isUser1 = data[FirestoreConversations.user1Id] == myUid;
    final otherId = isUser1
        ? (data[FirestoreConversations.user2Id] as String?)
        : (data[FirestoreConversations.user1Id] as String?);
    final otherName = isUser1
        ? (data[FirestoreConversations.user2DisplayName] as String?)
        : (data[FirestoreConversations.user1DisplayName] as String?);
    final otherIn = isUser1
        ? (data[FirestoreConversations.user2Initials] as String?)
        : (data[FirestoreConversations.user1Initials] as String?);
    final lastAt = data[FirestoreConversations.lastMessageAt] as Timestamp?;
    return ConversationSummary(
      conversationId: id,
      otherUserId: otherId ?? '',
      otherDisplayName: otherName ?? '?',
      otherInitials: otherIn ?? '?',
      lastMessageText:
          data[FirestoreConversations.lastMessageText] as String? ?? '',
      lastMessageAt: lastAt?.toDate(),
    );
  }

  static AdminConversationSummary _docToAdminSummary(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final lastAt = data[FirestoreConversations.lastMessageAt] as Timestamp?;
    return AdminConversationSummary(
      conversationId: doc.id,
      user1Id: data[FirestoreConversations.user1Id] as String? ?? '',
      user1DisplayName:
          data[FirestoreConversations.user1DisplayName] as String? ?? 'User 1',
      user1Initials:
          data[FirestoreConversations.user1Initials] as String? ?? '?',
      user2Id: data[FirestoreConversations.user2Id] as String? ?? '',
      user2DisplayName:
          data[FirestoreConversations.user2DisplayName] as String? ?? 'User 2',
      user2Initials:
          data[FirestoreConversations.user2Initials] as String? ?? '?',
      lastMessageText:
          data[FirestoreConversations.lastMessageText] as String? ?? '',
      lastMessageAt: lastAt?.toDate(),
    );
  }
}
