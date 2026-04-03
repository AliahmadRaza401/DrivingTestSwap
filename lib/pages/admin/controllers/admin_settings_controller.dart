import 'package:get/get.dart';

import '../../../core/services/admin_service.dart';
import '../../../routes/app_routes.dart';

class AdminSettingsController extends GetxController {
  void openSubscriptionManagement() {
    Get.toNamed(AppRoutes.adminSubscriptions);
  }

  void openPaymentOverview() {
    Get.toNamed(AppRoutes.adminPayments);
  }

  Future<void> logout() async {
    await AdminService.signOutAdmin();
    Get.offAllNamed(AppRoutes.login);
  }
}
