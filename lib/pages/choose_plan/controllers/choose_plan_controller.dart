import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/constants/iap_products.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/coupon_service.dart';
import '../../../core/services/iap_service.dart';
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

  // In-App Purchase (iOS) state.
  final RxMap<String, ProductDetails> products = <String, ProductDetails>{}.obs;
  final RxBool productsReady = false.obs;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  SubscriptionPlan? _pendingPlan;
  bool _restoring = false;

  /// True on iOS, where digital plans must use Apple In-App Purchase. On other
  /// platforms (Android) the app keeps using Stripe.
  bool get isIos => GetPlatform.isIOS;

  @override
  void onInit() {
    super.onInit();
    loadData();
    if (isIos) _initIap();
  }

  @override
  void onClose() {
    couponTextController.dispose();
    _purchaseSub?.cancel();
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

  // ---------------------------------------------------------------------------
  // In-App Purchase (iOS)
  // ---------------------------------------------------------------------------

  Future<void> _initIap() async {
    try {
      final available = await IapService.isStoreAvailable();
      if (!available) return;
      _purchaseSub = IapService.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error) {
          isSubmitting.value = false;
        },
      );
      await _loadIapProducts();
    } catch (_) {
      // Store unavailable — iOS users will still see plan prices from Firestore.
    }
  }

  Future<void> _loadIapProducts() async {
    final details = await IapService.loadProducts(IapProducts.all);
    products.assignAll({for (final d in details) d.id: d});
    productsReady.value = true;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isSubmitting.value = true;
          break;
        case PurchaseStatus.canceled:
          isSubmitting.value = false;
          _pendingPlan = null;
          if (purchase.pendingCompletePurchase) {
            await IapService.complete(purchase);
          }
          break;
        case PurchaseStatus.error:
          isSubmitting.value = false;
          _pendingPlan = null;
          if (purchase.pendingCompletePurchase) {
            await IapService.complete(purchase);
          }
          ToastUtil.error(
            purchase.error?.message ?? 'Purchase failed. Please try again.',
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchase);
          if (purchase.pendingCompletePurchase) {
            await IapService.complete(purchase);
          }
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final plan = _planForProductId(purchase.productID) ?? _pendingPlan;
    _pendingPlan = null;
    if (plan == null) {
      isSubmitting.value = false;
      return;
    }
    try {
      final priceValue = PaymentService.normalizeAmount(plan.price);
      final now = DateTime.now();
      final expiresAt = DateTime(
        now.year,
        now.month + plan.durationInMonths,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      await PaymentService.savePaymentRecord(
        paymentIntentId:
            purchase.purchaseID ?? 'IAP-${now.millisecondsSinceEpoch}',
        planId: plan.id,
        planTitle: plan.title,
        amount: priceValue.toStringAsFixed(2),
        originalAmount: priceValue.toStringAsFixed(2),
        discountAmount: '0',
        currency: plan.currency,
        period: plan.durationLabel,
      );
      await AuthService.saveUserSubscription(
        planId: plan.id,
        planTitle: plan.title,
        price: _displayPriceForPlan(plan),
        period: plan.durationLabel,
        expiresAt: expiresAt,
      );
      final wasRestore = purchase.status == PurchaseStatus.restored;
      isSubmitting.value = false;
      _restoring = false;
      ToastUtil.success(
        wasRestore
            ? 'Your subscription has been restored.'
            : 'Congratulations! Your subscription is active.',
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      isSubmitting.value = false;
      ToastUtil.error(
        'Purchase went through but activation failed. Tap Restore Purchases.',
      );
    }
  }

  SubscriptionPlan? _planForProductId(String productId) {
    for (final plan in plans) {
      if (IapService.productIdForPlan(plan) == productId) return plan;
    }
    return null;
  }

  Future<void> restorePurchases() async {
    if (!isIos || isSubmitting.value) return;
    _restoring = true;
    isSubmitting.value = true;
    try {
      await IapService.restore();
      // Restored purchases arrive via the stream. If none arrive, reset.
      await Future.delayed(const Duration(seconds: 3));
      if (_restoring && isSubmitting.value) {
        isSubmitting.value = false;
        _restoring = false;
        ToastUtil.info('No active subscription found to restore.');
      }
    } catch (e) {
      isSubmitting.value = false;
      _restoring = false;
      ToastUtil.error('Could not restore purchases. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Plan selection & pricing
  // ---------------------------------------------------------------------------

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
    // Coupons only apply on non-iOS (Apple IAP does not support custom coupons).
    if (isIos) return 0;
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

  /// Price string for a plan card, using the live App Store price on iOS so it
  /// always matches what StoreKit will charge (and the correct storefront).
  String displayPriceForPlan(SubscriptionPlan plan) =>
      _displayPriceForPlan(plan);

  String _displayPriceForPlan(SubscriptionPlan plan) {
    if (isIos) {
      // Touch the reactive flag so cards refresh when products load.
      productsReady.value;
      final productId = IapService.productIdForPlan(plan);
      final product = productId != null ? products[productId] : null;
      if (product != null) return product.price;
    }
    final raw = plan.price;
    return raw.startsWith('£') ? raw : '£$raw';
  }

  /// Label for the checkout button ("Free", the App Store price on iOS, or the
  /// coupon-adjusted total on Android).
  String get checkoutPriceLabel {
    final plan = selectedPlan;
    if (plan == null) return '';
    if (finalPriceValue <= 0) return 'Free';
    if (isIos) return _displayPriceForPlan(plan);
    return formattedFinalPrice;
  }

  // ---------------------------------------------------------------------------
  // Coupons (non-iOS only)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------------------

  Future<void> continueWithPlan() async {
    final plan = selectedPlan;
    if (plan == null || isSubmitting.value) return;

    // Free plans (e.g. the Founder plan) are granted directly on every platform.
    if (finalPriceValue <= 0) {
      await _activateFreePlan(plan);
      return;
    }

    if (isIos) {
      await _purchaseWithIap(plan);
    } else {
      await _purchaseWithStripe(plan);
    }
  }

  Future<void> _activateFreePlan(SubscriptionPlan plan) async {
    isSubmitting.value = true;
    try {
      final now = DateTime.now();
      await PaymentService.savePaymentRecord(
        paymentIntentId: 'FREE-${now.millisecondsSinceEpoch}',
        planId: plan.id,
        planTitle: plan.title,
        amount: '0',
        originalAmount: selectedPlanPriceValue.toStringAsFixed(2),
        discountAmount: discountValue.toStringAsFixed(2),
        couponCode: appliedCoupon.value?.code,
        couponName: appliedCoupon.value?.name,
        currency: plan.currency,
        period: plan.durationLabel,
      );
      if (!isIos && appliedCoupon.value != null) {
        await CouponService.markCouponRedeemed(appliedCoupon.value!.code);
      }
      final expiresAt = DateTime(
        now.year,
        now.month + plan.durationInMonths,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      await AuthService.saveUserSubscription(
        planId: plan.id,
        planTitle: plan.title,
        price: 'Free',
        period: plan.durationLabel,
        expiresAt: expiresAt,
      );
      ToastUtil.success('Your subscription is active.');
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      ToastUtil.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _purchaseWithIap(SubscriptionPlan plan) async {
    final productId = IapService.productIdForPlan(plan);
    if (productId == null) {
      ToastUtil.error('This plan is not available for purchase on iOS.');
      return;
    }
    var product = products[productId];
    if (product == null) {
      // Products may not have finished loading (or failed transiently) — try
      // fetching once more before giving up.
      try {
        await _loadIapProducts();
      } catch (_) {}
      product = products[productId];
    }
    if (product == null) {
      ToastUtil.error(
        'This plan isn\'t available from the App Store yet. Make sure you are '
        'signed in with a Sandbox account and the subscription is set up in '
        'App Store Connect.',
      );
      return;
    }
    _pendingPlan = plan;
    isSubmitting.value = true;
    try {
      await IapService.buy(product);
      // Result is delivered asynchronously via _onPurchaseUpdates.
    } catch (e) {
      isSubmitting.value = false;
      _pendingPlan = null;
      ToastUtil.error('Could not start the purchase. Please try again.');
    }
  }

  Future<void> _purchaseWithStripe(SubscriptionPlan plan) async {
    final stripeController = Get.put(StripePaymentController());
    isSubmitting.value = true;
    try {
      stripeController.isLoading.value = true;
      final stripeAmount = finalPriceValue.toStringAsFixed(2);
      final paymentIntent = await stripeController.initPaymentSheet(
        amount: stripeAmount,
        currency: plan.currency,
        merchantName: 'Driving Test Swap',
      );
      stripeController.isLoading.value = false;
      await stripeController.presentPaymentSheet();
      final paymentIntentId =
          paymentIntent['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString();
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
      final now = DateTime.now();
      final expiresAt = DateTime(
        now.year,
        now.month + plan.durationInMonths,
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
      ToastUtil.success('Congratulations! Your subscription is active.');
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
}
