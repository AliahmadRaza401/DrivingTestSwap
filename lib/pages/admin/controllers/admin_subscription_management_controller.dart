import 'package:get/get.dart';

import '../../../core/services/subscription_plan_service.dart';
import '../../../core/utils/toast_util.dart';

class AdminSubscriptionManagementController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPlans();
  }

  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      plans.assignAll(await SubscriptionPlanService.fetchPlans());
    } catch (_) {
      hasError.value = true;
      plans.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePlan(SubscriptionPlan plan) async {
    await SubscriptionPlanService.savePlan(plan);
    ToastUtil.success('Plan saved');
    await loadPlans();
  }

  Future<void> deletePlan(String planId) async {
    await SubscriptionPlanService.deletePlan(planId);
    ToastUtil.success('Plan deleted');
    await loadPlans();
  }

  Future<void> seedDefaults() async {
    await SubscriptionPlanService.seedDefaultPlans();
    ToastUtil.success('Default plans added');
    await loadPlans();
  }
}
