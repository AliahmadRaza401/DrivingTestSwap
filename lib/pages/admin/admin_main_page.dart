import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'admin_coupon_management_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_messages_page.dart';
import 'admin_payment_overview_page.dart';
import 'admin_settings_page.dart';
import 'admin_subscription_management_page.dart';
import 'admin_tests_page.dart';
import 'admin_users_page.dart';
import 'controllers/admin_coupon_management_controller.dart';
import 'controllers/admin_dashboard_controller.dart';
import 'controllers/admin_main_controller.dart';
import 'controllers/admin_messages_controller.dart';
import 'controllers/admin_settings_controller.dart';
import 'controllers/admin_subscription_management_controller.dart';
import 'controllers/admin_tests_controller.dart';
import 'controllers/admin_users_controller.dart';

class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final controller = Get.put(AdminMainController());
    final settingsController = Get.put(AdminSettingsController());
    Get.put(AdminDashboardController());
    Get.put(AdminUsersController());
    Get.put(AdminTestsController());
    Get.put(AdminMessagesController());
    Get.put(AdminSubscriptionManagementController());
    Get.put(AdminCouponManagementController());

    const pages = <Widget>[
      AdminDashboardPage(),
      AdminUsersPage(),
      AdminTestsPage(),
      AdminMessagesPage(),
      AdminSettingsPage(),
      AdminPaymentOverviewPage(),
      AdminSubscriptionManagementPage(),
      AdminCouponManagementPage(),
    ];

    const drawerItems = <_AdminDrawerItemData>[
      _AdminDrawerItemData(
        index: AdminMainController.dashboardIndex,
        title: 'Dashboard',
        subtitle: 'Overview and platform stats',
        icon: Icons.dashboard_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.usersIndex,
        title: 'Users',
        subtitle: 'Registered members and plans',
        icon: Icons.group_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.testsIndex,
        title: 'Tests',
        subtitle: 'Posts and swap records',
        icon: Icons.fact_check_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.messagesIndex,
        title: 'Messages',
        subtitle: 'User conversations',
        icon: Icons.forum_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.settingsIndex,
        title: 'Settings',
        subtitle: 'Admin tools and account',
        icon: Icons.settings_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.paymentsIndex,
        title: 'Payments',
        subtitle: 'Transactions and revenue',
        icon: Icons.payments_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.subscriptionsIndex,
        title: 'Packages',
        subtitle: 'Manage subscription plans',
        icon: Icons.card_membership_rounded,
      ),
      _AdminDrawerItemData(
        index: AdminMainController.couponsIndex,
        title: 'Coupons',
        subtitle: 'Discount codes and status',
        icon: Icons.confirmation_number_rounded,
      ),
    ];

    return Scaffold(
      key: scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.28),
      drawerEdgeDragWidth: 28,
      drawer: Obx(
        () => _AdminDrawer(
          selectedIndex: controller.currentIndex.value,
          items: drawerItems,
          onLogout: settingsController.logout,
          onSelect: (index) {
            Navigator.of(context).pop();
            controller.setIndex(index);
          },
        ),
      ),
      body: Obx(
        () => Stack(
          children: [
            IndexedStack(
              index: controller.currentIndex.value,
              children: pages,
            ),
            Positioned(
              top: 18,
              left: 18,
              child: SafeArea(
                child: _DrawerToggleButton(
                  onTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerToggleButton extends StatelessWidget {
  const _DrawerToggleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: const Icon(
              Icons.menu_rounded,
              key: ValueKey('menu'),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.selectedIndex,
    required this.items,
    required this.onLogout,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_AdminDrawerItemData> items;
  final Future<void> Function() onLogout;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      width: 300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAGES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _AdminDrawerTile(
                        item: item,
                        isSelected: item.index == selectedIndex,
                        onTap: () => onSelect(item.index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _DrawerLogoutButton(onTap: onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerLogoutButton extends StatelessWidget {
  const _DrawerLogoutButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.logoutRed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Log Out Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AdminDrawerTile extends StatelessWidget {
  const _AdminDrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _AdminDrawerItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDrawerItemData {
  const _AdminDrawerItemData({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
}
