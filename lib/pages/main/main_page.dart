import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
import '../../routes/app_routes.dart';
import '../noticeboard/noticeboard_page.dart';
import '../messages/messages_page.dart';
import '../post_availability/post_availability_page.dart';
import '../my_posts/my_posts_page.dart';
import '../profile/profile_page.dart';
import 'controllers/main_controller.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainController());
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
            children: const [
              NoticeboardPage(),
              MessagesPage(),
              PostAvailabilityPage(),
              MyPostsPage(),
              ProfilePage(),
            ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(controller: controller),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.controller});

  final MainController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: controller.currentIndex.value == 0,
                onTap: () => controller.setIndex(0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                isSelected: controller.currentIndex.value == 1,
                onTap: () => controller.setIndex(1),
              ),
              _CenterPostButton(
                onTap: () {
                  AuthService.hasActiveSubscription().then((has) {
                    if (has) {
                      controller.setIndex(2);
                    } else {
                      ToastUtil.info('Subscribe to add a post');
                      Get.toNamed(AppRoutes.choosePlan);
                    }
                  });
                },
              ),
              _NavItem(
                icon: Icons.description_outlined,
                label: 'My Posts',
                isSelected: controller.currentIndex.value == 3,
                onTap: () => controller.setIndex(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: controller.currentIndex.value == 4,
                onTap: () => controller.setIndex(4),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPostButton extends StatelessWidget {
  const _CenterPostButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        Text(
          'Post',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
