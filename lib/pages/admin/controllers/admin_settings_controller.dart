import 'package:get/get.dart';

import '../../../core/services/admin_service.dart';
import '../../../routes/app_routes.dart';
import 'admin_main_controller.dart';

class AdminSettingsController extends GetxController {
  void openAdminManagement() {
    if (Get.isRegistered<AdminMainController>()) {
      Get.find<AdminMainController>().setIndex(
        AdminMainController.dashboardIndex,
      );
      return;
    }
    Get.offAllNamed(AppRoutes.adminHome);
  }

  void openSubscriptionManagement() {
    if (Get.isRegistered<AdminMainController>()) {
      Get.find<AdminMainController>().setIndex(
        AdminMainController.subscriptionsIndex,
      );
      return;
    }
    Get.toNamed(AppRoutes.adminSubscriptions);
  }

  void openCouponManagement() {
    if (Get.isRegistered<AdminMainController>()) {
      Get.find<AdminMainController>().setIndex(AdminMainController.couponsIndex);
      return;
    }
    Get.toNamed(AppRoutes.adminCoupons);
  }

  void openPaymentOverview() {
    if (Get.isRegistered<AdminMainController>()) {
      Get.find<AdminMainController>().setIndex(AdminMainController.paymentsIndex);
      return;
    }
    Get.toNamed(AppRoutes.adminPayments);
  }

  Future<void> logout() async {
    await AdminService.signOutAdmin();
    Get.offAllNamed(AppRoutes.login);
  }
}
