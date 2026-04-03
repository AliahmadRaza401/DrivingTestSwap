import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.iconKey,
    required this.title,
    required this.price,
    required this.period,
    required this.currency,
    required this.features,
    required this.popular,
    required this.savePercent,
    required this.isGreenCheck,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String iconKey;
  final String title;
  final String price;
  final String period;
  final String currency;
  final List<String> features;
  final bool popular;
  final int? savePercent;
  final bool isGreenCheck;
  final bool isActive;
  final int sortOrder;

  int get durationInMonths {
    final match = RegExp(r'(\d+)').firstMatch(period);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String get durationLabel {
    final months = durationInMonths;
    return '$months ${months == 1 ? 'month' : 'months'}';
  }

  factory SubscriptionPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SubscriptionPlan(
      id: doc.id,
      iconKey: data['iconKey'] as String? ?? 'premium',
      title: data['title'] as String? ?? '',
      price: data['price'] as String? ?? '',
      period: data['period'] as String? ?? '',
      currency: data['currency'] as String? ?? 'gbp',
      features: ((data['features'] as List?) ?? const [])
          .whereType<String>()
          .map((feature) => feature.trim())
          .where((feature) => feature.isNotEmpty)
          .toList(),
      popular: data['popular'] as bool? ?? false,
      savePercent: (data['savePercent'] as num?)?.toInt(),
      isGreenCheck: data['isGreenCheck'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'iconKey': iconKey,
      'title': title,
      'price': price,
      'period': period,
      'currency': currency,
      'features': features,
      'popular': popular,
      'savePercent': savePercent,
      'isGreenCheck': isGreenCheck,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  IconData get icon {
    switch (iconKey) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'star':
        return Icons.star_outline_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'workspace':
        return Icons.workspace_premium_rounded;
      case 'premium':
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  SubscriptionPlan copyWith({
    String? id,
    String? iconKey,
    String? title,
    String? price,
    String? period,
    String? currency,
    List<String>? features,
    bool? popular,
    int? savePercent,
    bool? clearSavePercent,
    bool? isGreenCheck,
    bool? isActive,
    int? sortOrder,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      iconKey: iconKey ?? this.iconKey,
      title: title ?? this.title,
      price: price ?? this.price,
      period: period ?? this.period,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      popular: popular ?? this.popular,
      savePercent: clearSavePercent == true
          ? null
          : (savePercent ?? this.savePercent),
      isGreenCheck: isGreenCheck ?? this.isGreenCheck,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class SubscriptionPlanService {
  SubscriptionPlanService._();

  static const String collection = 'subscription_plans';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<SubscriptionPlan> get defaultPlans => const [
    SubscriptionPlan(
      id: 'monthly',
      iconKey: 'bolt',
      title: 'Monthly',
      price: '£4.99',
      period: '1',
      currency: 'gbp',
      features: [
        'Instant test swap alerts',
        'Search by location & date',
        'Cancel anytime',
      ],
      popular: false,
      savePercent: null,
      isGreenCheck: false,
      isActive: true,
      sortOrder: 1,
    ),
    SubscriptionPlan(
      id: '3months',
      iconKey: 'workspace',
      title: '3 Months',
      price: '£12.99',
      period: '3',
      currency: 'gbp',
      features: [
        'Instant test swap alerts',
        'Search by location & date',
        'Priority notification',
        'Best value for most learner',
      ],
      popular: true,
      savePercent: 13,
      isGreenCheck: true,
      isActive: true,
      sortOrder: 2,
    ),
    SubscriptionPlan(
      id: '6months',
      iconKey: 'star',
      title: '6 Months',
      price: '£24.99',
      period: '6',
      currency: 'gbp',
      features: [
        'Instant test swap alerts',
        'Search by location & date',
        'Priority notification',
        'Extended coverage period',
      ],
      popular: false,
      savePercent: 17,
      isGreenCheck: false,
      isActive: true,
      sortOrder: 3,
    ),
  ];

  static Stream<List<SubscriptionPlan>> streamPlans({bool activeOnly = true}) {
    return _firestore
        .collection(collection)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          var plans = snapshot.docs
              .map((doc) => SubscriptionPlan.fromFirestore(doc))
              .toList();
          if (activeOnly) {
            plans = plans.where((plan) => plan.isActive).toList();
          }
          return plans;
        });
  }

  static Future<List<SubscriptionPlan>> fetchPlans({
    bool activeOnly = false,
  }) async {
    final snapshot = await _firestore
        .collection(collection)
        .orderBy('sortOrder')
        .get();
    var plans = snapshot.docs
        .map((doc) => SubscriptionPlan.fromFirestore(doc))
        .toList();
    if (activeOnly) {
      plans = plans.where((plan) => plan.isActive).toList();
    }
    return plans;
  }

  static Future<void> savePlan(SubscriptionPlan plan) async {
    await _firestore.collection(collection).doc(plan.id).set({
      ...plan.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deletePlan(String planId) async {
    await _firestore.collection(collection).doc(planId).delete();
  }

  static Future<String> generateUniquePlanId() async {
    for (var number = 1000; number <= 9999; number++) {
      final id = number.toString();
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) {
        return id;
      }
    }
    throw Exception('No available 4-digit plan ID remaining.');
  }

  static Future<void> seedDefaultPlans() async {
    final existing = await fetchPlans();
    if (existing.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final plan in defaultPlans) {
      final ref = _firestore.collection(collection).doc(plan.id);
      batch.set(ref, {
        ...plan.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
