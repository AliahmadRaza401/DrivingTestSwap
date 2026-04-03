import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_preferences_service.dart';

abstract class FirestorePayments {
  static const String collection = 'payments';
  static const String paymentIntentId = 'paymentIntentId';
  static const String userId = 'userId';
  static const String userEmail = 'userEmail';
  static const String userName = 'userName';
  static const String planId = 'planId';
  static const String planTitle = 'planTitle';
  static const String amount = 'amount';
  static const String amountValue = 'amountValue';
  static const String currency = 'currency';
  static const String period = 'period';
  static const String status = 'status';
  static const String paidAt = 'paidAt';
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.paymentIntentId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.planId,
    required this.planTitle,
    required this.amount,
    required this.amountValue,
    required this.currency,
    required this.period,
    required this.status,
    required this.paidAt,
  });

  final String id;
  final String paymentIntentId;
  final String userId;
  final String userEmail;
  final String userName;
  final String planId;
  final String planTitle;
  final String amount;
  final double amountValue;
  final String currency;
  final String period;
  final String status;
  final DateTime paidAt;

  factory PaymentRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PaymentRecord(
      id: doc.id,
      paymentIntentId: data[FirestorePayments.paymentIntentId] as String? ?? '',
      userId: data[FirestorePayments.userId] as String? ?? '',
      userEmail: data[FirestorePayments.userEmail] as String? ?? '',
      userName: data[FirestorePayments.userName] as String? ?? '',
      planId: data[FirestorePayments.planId] as String? ?? '',
      planTitle: data[FirestorePayments.planTitle] as String? ?? '',
      amount: data[FirestorePayments.amount] as String? ?? '0.00',
      amountValue:
          (data[FirestorePayments.amountValue] as num?)?.toDouble() ?? 0,
      currency: data[FirestorePayments.currency] as String? ?? 'gbp',
      period: data[FirestorePayments.period] as String? ?? '',
      status: data[FirestorePayments.status] as String? ?? 'paid',
      paidAt:
          (data[FirestorePayments.paidAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}

class PaymentService {
  PaymentService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> savePaymentRecord({
    required String paymentIntentId,
    required String planId,
    required String planTitle,
    required String amount,
    required String currency,
    required String period,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final fullName = await UserPreferencesService.fullName ?? '';
    final normalizedAmount = normalizeAmount(amount);
    await _firestore
        .collection(FirestorePayments.collection)
        .doc(paymentIntentId)
        .set({
          FirestorePayments.paymentIntentId: paymentIntentId,
          FirestorePayments.userId: user.uid,
          FirestorePayments.userEmail: user.email ?? '',
          FirestorePayments.userName: fullName,
          FirestorePayments.planId: planId,
          FirestorePayments.planTitle: planTitle,
          FirestorePayments.amount: formatAmount(amount),
          FirestorePayments.amountValue: normalizedAmount,
          FirestorePayments.currency: currency,
          FirestorePayments.period: period,
          FirestorePayments.status: 'paid',
          FirestorePayments.paidAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Stream<List<PaymentRecord>> streamMyPayments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _firestore
        .collection(FirestorePayments.collection)
        .where(FirestorePayments.userId, isEqualTo: user.uid)
        .orderBy(FirestorePayments.paidAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PaymentRecord.fromFirestore).toList(),
        );
  }

  static Stream<List<PaymentRecord>> streamAllPayments() {
    return _firestore
        .collection(FirestorePayments.collection)
        .orderBy(FirestorePayments.paidAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PaymentRecord.fromFirestore).toList(),
        );
  }

  static double normalizeAmount(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  static String formatAmount(String raw) {
    final value = normalizeAmount(raw);
    return '£${value.toStringAsFixed(2)}';
  }
}
