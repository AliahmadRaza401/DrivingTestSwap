import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class CouponRecord {
  const CouponRecord({
    required this.id,
    required this.name,
    required this.code,
    required this.discountAmount,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.usageCount,
  });

  final String id;
  final String name;
  final String code;
  final double discountAmount;
  final String currency;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int usageCount;

  String get formattedDiscount =>
      CouponService.formatCurrency(discountAmount, currency: currency);

  factory CouponRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CouponRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: CouponService.normalizeCode(data['code'] as String? ?? doc.id),
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'gbp',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      usageCount: (data['usageCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': CouponService.normalizeCode(code),
      'discountAmount': discountAmount,
      'currency': currency,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CouponRecord copyWith({
    String? id,
    String? name,
    String? code,
    double? discountAmount,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
  }) {
    return CouponRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      discountAmount: discountAmount ?? this.discountAmount,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

class CouponService {
  CouponService._();

  static const String collection = 'coupons';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();
  static const String _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static Stream<List<CouponRecord>> streamCoupons() {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CouponRecord.fromFirestore)
              .toList(growable: false),
        );
  }

  static Future<List<CouponRecord>> fetchCoupons() async {
    final snapshot = await _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(CouponRecord.fromFirestore)
        .toList(growable: false);
  }

  static Future<CouponRecord?> findCouponByCode(String code) async {
    final normalizedCode = normalizeCode(code);
    if (normalizedCode.isEmpty) return null;
    final doc = await _firestore.collection(collection).doc(normalizedCode).get();
    if (!doc.exists) return null;
    return CouponRecord.fromFirestore(doc);
  }

  static Future<CouponRecord?> validateCoupon(
    String code, {
    String? currency,
  }) async {
    final coupon = await findCouponByCode(code);
    if (coupon == null || !coupon.isActive) return null;
    if (currency != null &&
        coupon.currency.trim().toLowerCase() != currency.trim().toLowerCase()) {
      return null;
    }
    return coupon;
  }

  static Future<void> saveCoupon(CouponRecord coupon) async {
    final normalizedCode = normalizeCode(coupon.code);
    await _firestore.collection(collection).doc(normalizedCode).set({
      ...coupon.copyWith(code: normalizedCode, id: normalizedCode).toMap(),
      'createdAt': coupon.createdAt != null
          ? Timestamp.fromDate(coupon.createdAt!)
          : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCoupon(String couponCode) async {
    await _firestore.collection(collection).doc(normalizeCode(couponCode)).delete();
  }

  static Future<String> generateUniqueCouponCode({int length = 8}) async {
    for (var attempt = 0; attempt < 50; attempt++) {
      final code = List.generate(
        length,
        (_) => _characters[_random.nextInt(_characters.length)],
      ).join();
      final doc = await _firestore.collection(collection).doc(code).get();
      if (!doc.exists) return code;
    }
    throw Exception('Unable to generate a unique coupon code.');
  }

  static Future<void> markCouponRedeemed(String couponCode) async {
    final normalizedCode = normalizeCode(couponCode);
    if (normalizedCode.isEmpty) return;
    await _firestore.collection(collection).doc(normalizedCode).set({
      'usageCount': FieldValue.increment(1),
      'lastRedeemedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static double normalizeAmount(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  static String formatCurrency(double amount, {String currency = 'gbp'}) {
    final symbol = switch (currency.trim().toLowerCase()) {
      'usd' => '\$',
      'eur' => '€',
      _ => '£',
    };
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
