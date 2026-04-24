import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/utils/toast_util.dart';

class AdminTestsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxInt selectedTabIndex = 0.obs;
  final Rxn<AdminTestsOverview> testsOverview = Rxn<AdminTestsOverview>();

  @override
  void onInit() {
    super.onInit();
    loadTests();
  }

  Future<void> loadTests() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      testsOverview.value = await AdminService.fetchTestsOverview();
    } catch (_) {
      hasError.value = true;
      testsOverview.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void setTabIndex(int index) {
    selectedTabIndex.value = index;
  }

  Future<void> deletePost(String id) async {
    final confirmed = await _confirmAction(
      title: 'Delete test post?',
      message: 'This will remove the test post from the noticeboard.',
    );
    if (confirmed != true) return;
    await AdminService.deletePost(id);
    ToastUtil.success('Test post deleted');
    await loadTests();
  }

  Future<void> deleteSwap(String id) async {
    final confirmed = await _confirmAction(
      title: 'Delete swap record?',
      message: 'This will permanently remove the swap record.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true) return;
    await AdminService.deleteSwap(id);
    ToastUtil.success('Swap record deleted');
    await loadTests();
  }

  Future<void> completeSwap(String id) async {
    final confirmed = await _confirmAction(
      title: 'Complete swap?',
      message: 'This will move the running swap into completed swaps.',
      confirmLabel: 'Complete',
    );
    if (confirmed != true) return;
    await AdminService.completeSwap(id);
    ToastUtil.success('Swap marked as completed');
    await loadTests();
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'Delete',
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
