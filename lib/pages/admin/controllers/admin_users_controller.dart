import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/admin_service.dart';

class AdminUsersController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString query = ''.obs;
  final RxList<AdminUserRecord> users = <AdminUserRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      users.assignAll(await AdminService.fetchUsers());
    } catch (_) {
      hasError.value = true;
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void updateQuery(String value) {
    query.value = value.trim();
  }

  List<AdminUserRecord> get filteredUsers {
    final currentQuery = query.value.toLowerCase();
    if (currentQuery.isEmpty) return users;
    return users.where((user) {
      return user.email.toLowerCase().contains(currentQuery) ||
          user.fullName.toLowerCase().contains(currentQuery);
    }).toList();
  }
}
