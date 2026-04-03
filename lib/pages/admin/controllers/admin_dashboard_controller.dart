import 'package:get/get.dart';

import '../../../core/services/admin_service.dart';

class AdminDashboardController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final Rxn<AdminDashboardStats> stats = Rxn<AdminDashboardStats>();

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      stats.value = await AdminService.fetchDashboardStats();
    } catch (_) {
      hasError.value = true;
      stats.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  String currency(double value) => '£${value.toStringAsFixed(2)}';
}
