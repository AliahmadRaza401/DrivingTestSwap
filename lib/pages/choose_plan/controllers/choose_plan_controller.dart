import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/coupon_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/services/subscription_plan_service.dart';
import '../../../core/utils/toast_util.dart';
import '../../../routes/app_routes.dart';

class ChoosePlanController extends GetxController {
  final TextEditingController couponTextController = TextEditingController();
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isApplyingCoupon = false.obs;
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final Rxn<SubscriptionStatus> subscriptionStatus = Rxn<SubscriptionStatus>();
  final Rxn<CouponRecord> appliedCoupon = Rxn<CouponRecord>();
  final RxString couponCodeInput = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    couponTextController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      subscriptionStatus.value = await AuthService.getSubscriptionStatus();
      final remotePlans = await SubscriptionPlanService.fetchPlans(
        activeOnly: true,
      );
      final loadedPlans = remotePlans.isNotEmpty
          ? remotePlans
          : SubscriptionPlanService.defaultPlans;
      plans.assignAll(loadedPlans);
      if (selectedIndex.value >= plans.length) {
        selectedIndex.value = plans.isEmpty ? 0 : 0;
      }
      if (plans.length > 1 && selectedIndex.value == 0) {
        final defaultIndex = plans.indexWhere((plan) => plan.id == '3months');
        if (defaultIndex >= 0) {
          selectedIndex.value = defaultIndex;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  SubscriptionPlan? get selectedPlan {
    if (plans.isEmpty) return null;
    final index = selectedIndex.value.clamp(0, plans.length - 1);
    return plans[index];
  }

  void selectPlan(int index) {
    selectedIndex.value = index;
  }

  void updateCouponCode(String value) {
    final normalized = CouponService.normalizeCode(value);
    couponCodeInput.value = normalized;
    if (appliedCoupon.value != null && appliedCoupon.value!.code != normalized) {
      appliedCoupon.value = null;
    }
    if (couponTextController.text != normalized) {
      couponTextController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
  }

  double get selectedPlanPriceValue {
    final plan = selectedPlan;
    if (plan == null) return 0;
    return PaymentService.normalizeAmount(plan.price);
  }

  double get discountValue {
    final discount = appliedCoupon.value?.discountAmount ?? 0;
    return discount > selectedPlanPriceValue ? selectedPlanPriceValue : discount;
  }

  double get finalPriceValue {
    final total = selectedPlanPriceValue - discountValue;
    if (total <= 0) return 0;
    return total;
  }

  String get formattedOriginalPrice => PaymentService.formatAmount(
    selectedPlan?.price ?? '0',
  );

  String get formattedDiscountPrice =>
      PaymentService.formatAmount(discountValue.toStringAsFixed(2));

  String get formattedFinalPrice =>
      PaymentService.formatAmount(finalPriceValue.toStringAsFixed(2));

  Future<void> applyCoupon() async {
    final plan = selectedPlan;
    final code = CouponService.normalizeCode(couponCodeInput.value);
    if (plan == null) return;
    if (code.isEmpty) {
      ToastUtil.warning('Enter a coupon code first.');
      return;
    }
    try {
      isApplyingCoupon.value = true;
      final coupon = await CouponService.validateCoupon(
        code,
        currency: plan.currency,
      );
      if (coupon == null) {
        appliedCoupon.value = null;
        ToastUtil.error('Coupon code is invalid or inactive.');
        return;
      }
      appliedCoupon.value = coupon;
      ToastUtil.success(
        'Coupon applied. You saved ${coupon.formattedDiscount}.',
      );
    } catch (e) {
      ToastUtil.error(e.toString());
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  void removeCoupon() {
    appliedCoupon.value = null;
    couponCodeInput.value = '';
    couponTextController.clear();
  }

  Future<void> continueWithPlan() async {
    final plan = selectedPlan;
    if (plan == null || isSubmitting.value) return;

    final stripeController = Get.put(StripePaymentController());
    isSubmitting.value = true;
    try {
      Map<String, dynamic> paymentIntent = {};
      var paymentIntentId = DateTime.now().millisecondsSinceEpoch.toString();
      if (finalPriceValue > 0) {
        stripeController.isLoading.value = true;
        final stripeAmount = finalPriceValue.toStringAsFixed(2);
        paymentIntent = await stripeController.initPaymentSheet(
          amount: stripeAmount,
          currency: plan.currency,
          merchantName: 'Driving Test Swap',
        );
        stripeController.isLoading.value = false;
        await stripeController.presentPaymentSheet();
        paymentIntentId =
            paymentIntent['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString();
      } else {
        paymentIntentId = 'FREE-${DateTime.now().millisecondsSinceEpoch}';
      }
      await PaymentService.savePaymentRecord(
        paymentIntentId: paymentIntentId,
        planId: plan.id,
        planTitle: plan.title,
        amount: finalPriceValue.toStringAsFixed(2),
        originalAmount: selectedPlanPriceValue.toStringAsFixed(2),
        discountAmount: discountValue.toStringAsFixed(2),
        couponCode: appliedCoupon.value?.code,
        couponName: appliedCoupon.value?.name,
        currency: plan.currency,
        period: plan.period,
      );
      if (appliedCoupon.value != null) {
        await CouponService.markCouponRedeemed(appliedCoupon.value!.code);
      }
      final months = _monthsFromPlan(plan);
      final now = DateTime.now();
      final expiresAt = DateTime(
        now.year,
        now.month + months,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      await AuthService.saveUserSubscription(
        planId: plan.id,
        planTitle: plan.title,
        price: formattedFinalPrice,
        period: plan.durationLabel,
        expiresAt: expiresAt,
      );
      ToastUtil.success(
        finalPriceValue > 0
            ? 'Congratulations! Your subscription is active.'
            : 'Coupon applied successfully. Your subscription is active.',
      );
      Get.offAllNamed(AppRoutes.home);
    } on StripeException catch (e) {
      stripeController.isLoading.value = false;
      if (e.error.code == FailureCode.Canceled) return;
      ToastUtil.error(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      stripeController.isLoading.value = false;
      ToastUtil.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  void openPublicView() {
    Get.offAllNamed(AppRoutes.home);
  }

  int _monthsFromPlan(SubscriptionPlan plan) {
    return plan.durationInMonths;
  }
}
