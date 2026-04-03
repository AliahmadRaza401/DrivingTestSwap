import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/services/subscription_plan_service.dart';
import '../../../core/utils/toast_util.dart';
import '../../../routes/app_routes.dart';

class ChoosePlanController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final Rxn<SubscriptionStatus> subscriptionStatus = Rxn<SubscriptionStatus>();

  @override
  void onInit() {
    super.onInit();
    loadData();
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

  Future<void> continueWithPlan() async {
    final plan = selectedPlan;
    if (plan == null || isSubmitting.value) return;

    final stripeController = Get.put(StripePaymentController());
    isSubmitting.value = true;
    stripeController.isLoading.value = true;
    try {
      final stripeAmount = plan.price.replaceAll(RegExp(r'[^0-9.]'), '');
      final paymentIntent = await stripeController.initPaymentSheet(
        amount: stripeAmount,
        currency: plan.currency,
        merchantName: 'Driving Test Swap',
      );
      stripeController.isLoading.value = false;
      await stripeController.presentPaymentSheet();
      await PaymentService.savePaymentRecord(
        paymentIntentId:
            paymentIntent['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        planId: plan.id,
        planTitle: plan.title,
        amount: plan.price,
        currency: plan.currency,
        period: plan.period,
      );
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
        price: plan.price,
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

  int _monthsFromPlan(SubscriptionPlan plan) {
    return plan.durationInMonths;
  }
}
