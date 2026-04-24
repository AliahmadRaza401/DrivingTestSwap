import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'payment_service.dart';
import 'post_service.dart';
import 'swap_service.dart';
import 'user_preferences_service.dart';

class AdminActivityPoint {
  const AdminActivityPoint({
    required this.label,
    required this.users,
    required this.posts,
    required this.swaps,
  });

  final String label;
  final int users;
  final int posts;
  final int swaps;
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.totalSwaps,
    required this.totalEarnings,
    required this.todaySwaps,
    required this.todayEarnings,
    required this.activity,
  });

  final int totalUsers;
  final int totalPosts;
  final int totalSwaps;
  final double totalEarnings;
  final int todaySwaps;
  final double todayEarnings;
  final List<AdminActivityPoint> activity;
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.createdAt,
    required this.subscriptionPlan,
    required this.subscriptionPrice,
    required this.postCount,
    required this.swapCount,
  });

  final String id;
  final String email;
  final String fullName;
  final String dateOfBirth;
  final DateTime? createdAt;
  final String subscriptionPlan;
  final String subscriptionPrice;
  final int postCount;
  final int swapCount;
}

class AdminSwapPostRecord {
  const AdminSwapPostRecord({
    required this.post,
    required this.ownerEmail,
    required this.ownerName,
  });

  final SwapPost post;
  final String ownerEmail;
  final String ownerName;
}

class AdminSwapRecord {
  const AdminSwapRecord({
    required this.swap,
    required this.initiatorName,
    required this.initiatorEmail,
    required this.targetName,
    required this.targetEmail,
    required this.initiatorPost,
    required this.targetPost,
  });

  final SwapRecord swap;
  final String? initiatorName;
  final String? initiatorEmail;
  final String? targetName;
  final String? targetEmail;
  final SwapPost? initiatorPost;
  final SwapPost? targetPost;
}

class AdminTestsOverview {
  const AdminTestsOverview({
    required this.posts,
    required this.runningSwaps,
    required this.completedSwaps,
  });

  final List<AdminSwapPostRecord> posts;
  final List<AdminSwapRecord> runningSwaps;
  final List<AdminSwapRecord> completedSwaps;
}

class AdminService {
  AdminService._();

  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '123456';
  static const String adminName = 'Administrator';
  static const String _adminUid = 'admin_local';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _asString(Object? value) => value?.toString() ?? '';

  static bool matchesStaticCredentials({
    required String email,
    required String password,
  }) {
    return email.trim().toLowerCase() == adminEmail &&
        password == adminPassword;
  }

  static Future<void> signInAsAdmin() async {
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
    await UserPreferencesService.saveUserAndLoginState(
      uid: _adminUid,
      email: adminEmail,
      fullName: adminName,
      role: UserPrefsKeys.roleAdmin,
    );
  }

  static Future<void> signOutAdmin() async {
    await UserPreferencesService.clearUserAndLoginState();
    if (_auth.currentUser != null) {
      await AuthService.signOut();
    }
  }

  static Future<AdminDashboardStats> fetchDashboardStats() async {
    final usersFuture = _firestore.collection(FirestoreUsers.collection).get();
    final postsFuture = _firestore.collection(FirestorePosts.collection).get();
    final swapsFuture = _firestore.collection(FirestoreSwaps.collection).get();
    final paymentsFuture = _firestore
        .collection(FirestorePayments.collection)
        .get();

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      usersFuture,
      postsFuture,
      swapsFuture,
      paymentsFuture,
    ]);

    final usersSnap = results[0];
    final postsSnap = results[1];
    final swapsSnap = results[2];
    final paymentsSnap = results[3];
    final todayStart = DateTime.now();
    final startOfToday = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day,
    );
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    final totalEarnings = paymentsSnap.docs.fold<double>(
      0,
      (runningTotal, doc) =>
          runningTotal +
          ((doc.data()[FirestorePayments.amountValue] as num?)?.toDouble() ??
              0),
    );
    final todayEarnings = paymentsSnap.docs.fold<double>(0, (
      runningTotal,
      doc,
    ) {
      final paidAt = doc.data()[FirestorePayments.paidAt];
      final isToday = _isTimestampInRange(
        paidAt,
        startOfToday,
        startOfTomorrow,
      );
      if (!isToday) {
        return runningTotal;
      }
      return runningTotal +
          ((doc.data()[FirestorePayments.amountValue] as num?)?.toDouble() ??
              0);
    });
    final todaySwaps = _countDocsOnDay(
      swapsSnap.docs,
      FirestoreSwaps.createdAt,
      startOfToday,
      startOfTomorrow,
    );

    return AdminDashboardStats(
      totalUsers: usersSnap.docs.length,
      totalPosts: postsSnap.docs.length,
      totalSwaps: swapsSnap.docs.length,
      totalEarnings: totalEarnings,
      todaySwaps: todaySwaps,
      todayEarnings: todayEarnings,
      activity: _buildRecentActivity(
        users: usersSnap.docs,
        posts: postsSnap.docs,
        swaps: swapsSnap.docs,
      ),
    );
  }

  static Future<List<AdminUserRecord>> fetchUsers() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _firestore.collection(FirestoreUsers.collection).get(),
      _firestore.collection(FirestorePosts.collection).get(),
      _firestore.collection(FirestoreSwaps.collection).get(),
    ]);

    final users = results[0].docs;
    final posts = results[1].docs;
    final swaps = results[2].docs;

    final postCounts = <String, int>{};
    for (final post in posts) {
      final userId = post.data()[FirestorePosts.userId] as String? ?? '';
      if (userId.isEmpty) continue;
      postCounts[userId] = (postCounts[userId] ?? 0) + 1;
    }

    final swapCounts = <String, int>{};
    for (final swap in swaps) {
      final data = swap.data();
      final initiatorId = data[FirestoreSwaps.initiatorUserId] as String? ?? '';
      final targetId = data[FirestoreSwaps.targetUserId] as String? ?? '';
      if (initiatorId.isNotEmpty) {
        swapCounts[initiatorId] = (swapCounts[initiatorId] ?? 0) + 1;
      }
      if (targetId.isNotEmpty) {
        swapCounts[targetId] = (swapCounts[targetId] ?? 0) + 1;
      }
    }

    final records = users.map((doc) {
      final data = doc.data();
      return AdminUserRecord(
        id: doc.id,
        email: data[FirestoreUsers.email] as String? ?? '',
        fullName: data[FirestoreUsers.fullName] as String? ?? '',
        dateOfBirth: data[FirestoreUsers.dateOfBirth] as String? ?? '',
        createdAt: (data[FirestoreUsers.createdAt] as Timestamp?)?.toDate(),
        subscriptionPlan:
            data[FirestoreUsers.subscriptionPlanTitle] as String? ?? '',
        subscriptionPrice:
            data[FirestoreUsers.subscriptionPrice] as String? ?? '',
        postCount: postCounts[doc.id] ?? 0,
        swapCount: swapCounts[doc.id] ?? 0,
      );
    }).toList();

    records.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );
    return records;
  }

  static Future<AdminTestsOverview> fetchTestsOverview() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _firestore.collection(FirestoreUsers.collection).get(),
      _firestore
          .collection(FirestorePosts.collection)
          .orderBy(FirestorePosts.createdAt, descending: true)
          .get(),
      _firestore
          .collection(FirestoreSwaps.collection)
          .orderBy(FirestoreSwaps.createdAt, descending: true)
          .get(),
    ]);

    final users = results[0].docs;
    final posts = results[1].docs;
    final swaps = results[2].docs;

    final userMap = {for (final user in users) user.id: user.data()};

    final postRecords = posts.map((doc) {
      final post = SwapPost.fromFirestore(doc);
      final owner = userMap[post.userId];
      final ownerName = _asString(owner?[FirestoreUsers.fullName]);
      return AdminSwapPostRecord(
        post: post,
        ownerEmail: _asString(owner?[FirestoreUsers.email]),
        ownerName: ownerName.isEmpty ? post.creatorName : ownerName,
      );
    }).toList();

    final postMap = {
      for (final record in postRecords) record.post.id: record.post,
    };

    final swapRecords = swaps.map((doc) {
      final swap = SwapRecord.fromFirestore(doc);
      return AdminSwapRecord(
        swap: swap,
        initiatorName: _asString(
          userMap[swap.initiatorUserId]?[FirestoreUsers.fullName],
        ),
        initiatorEmail: _asString(
          userMap[swap.initiatorUserId]?[FirestoreUsers.email],
        ),
        targetName: _asString(
          userMap[swap.targetUserId]?[FirestoreUsers.fullName],
        ),
        targetEmail: _asString(
          userMap[swap.targetUserId]?[FirestoreUsers.email],
        ),
        initiatorPost: postMap[swap.initiatorPostId],
        targetPost: postMap[swap.targetPostId],
      );
    }).toList();

    final runningSwaps = swapRecords
        .where((record) => !record.swap.isCompleted)
        .toList();
    final completedSwaps = swapRecords
        .where((record) => record.swap.isCompleted)
        .toList();

    return AdminTestsOverview(
      posts: postRecords,
      runningSwaps: runningSwaps,
      completedSwaps: completedSwaps,
    );
  }

  static Future<void> deletePost(String postId) {
    return _firestore
        .collection(FirestorePosts.collection)
        .doc(postId)
        .delete();
  }

  static Future<void> deleteSwap(String swapId) {
    return _firestore
        .collection(FirestoreSwaps.collection)
        .doc(swapId)
        .delete();
  }

  static Future<void> completeSwap(String swapId) {
    return _firestore.collection(FirestoreSwaps.collection).doc(swapId).update({
      FirestoreSwaps.status: FirestoreSwaps.statusCompleted,
    });
  }

  static List<AdminActivityPoint> _buildRecentActivity({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> swaps,
  }) {
    final now = DateTime.now();
    final points = <AdminActivityPoint>[];

    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      final nextDay = day.add(const Duration(days: 1));
      points.add(
        AdminActivityPoint(
          label: _dayLabel(day.weekday),
          users: _countDocsOnDay(users, FirestoreUsers.createdAt, day, nextDay),
          posts: _countDocsOnDay(posts, FirestorePosts.createdAt, day, nextDay),
          swaps: _countDocsOnDay(swaps, FirestoreSwaps.createdAt, day, nextDay),
        ),
      );
    }

    return points;
  }

  static int _countDocsOnDay(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String field,
    DateTime start,
    DateTime end,
  ) {
    return docs.where((doc) {
      final timestamp = doc.data()[field];
      if (timestamp is! Timestamp) return false;
      final date = timestamp.toDate();
      return !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  static bool _isTimestampInRange(Object? value, DateTime start, DateTime end) {
    if (value is! Timestamp) {
      return false;
    }
    final date = value.toDate();
    return !date.isBefore(start) && date.isBefore(end);
  }

  static String _dayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}
