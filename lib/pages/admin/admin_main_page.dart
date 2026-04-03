import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'admin_dashboard_page.dart';
import 'admin_messages_page.dart';
import 'admin_settings_page.dart';
import 'admin_tests_page.dart';
import 'admin_users_page.dart';
import 'controllers/admin_dashboard_controller.dart';
import 'controllers/admin_main_controller.dart';
import 'controllers/admin_messages_controller.dart';
import 'controllers/admin_settings_controller.dart';
import 'controllers/admin_tests_controller.dart';
import 'controllers/admin_users_controller.dart';

class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminMainController());
    Get.put(AdminDashboardController());
    Get.put(AdminUsersController());
    Get.put(AdminTestsController());
    Get.put(AdminMessagesController());
    Get.put(AdminSettingsController());
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            AdminDashboardPage(),
            AdminUsersPage(),
            AdminTestsPage(),
            AdminMessagesPage(),
            AdminSettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.setIndex,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            );
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
