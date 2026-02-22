import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'privacy_policy_page.dart';
import 'security_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _SettingsSection(
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => Get.to(() => const EditProfilePage()),
              ),
              _SettingsItem(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () => Get.to(() => const ChangePasswordPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Privacy & Security',
            items: [
              _SettingsItem(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () => Get.to(() => const PrivacyPolicyPage()),
              ),
              _SettingsItem(
                icon: Icons.verified_user_outlined,
                label: 'Security',
                onTap: () => Get.to(() => const SecurityPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: AppColors.border),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: AppColors.textPrimary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
    );
  }
}
