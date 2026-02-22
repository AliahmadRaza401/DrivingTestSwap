import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../routes/app_routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static Future<_ProfileData?> _loadProfileData() async {
    final fullName = await UserPreferencesService.fullName;
    final email = await UserPreferencesService.email;
    final subscription = await AuthService.getSubscriptionStatus();
    if (email == null || email.isEmpty) return null;
    final initials = _initialsFromName(fullName ?? '');
    return _ProfileData(
      fullName: fullName?.trim().isNotEmpty == true ? fullName!.trim() : 'User',
      email: email,
      initials: initials,
      planTitle: subscription?.planTitle,
    );
  }

  static String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              FutureBuilder<_ProfileData?>(
                future: _loadProfileData(),
                builder: (context, snapshot) {
                  return _buildProfileHeader(
                    fullName: snapshot.data?.fullName ?? '—',
                    email: snapshot.data?.email ?? '—',
                    initials: snapshot.data?.initials ?? '?',
                    planTitle: snapshot.data?.planTitle,
                    loading: snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
              const SizedBox(height: 32),
              FutureBuilder<_ProfileData?>(
                future: _loadProfileData(),
                builder: (context, snapshot) {
                  final planTitle = snapshot.data?.planTitle ?? '';
                  final hasPlan = planTitle.isNotEmpty;
                  return _buildMenuRow(
                    icon: Icons.card_membership_rounded,
                    label: 'Membership Plan',
                    onTap: () => Get.toNamed(AppRoutes.choosePlan),
                    trailing: hasPlan
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.premiumYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              planTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.premiumOrange,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
              _buildMenuRow(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => Get.toNamed(AppRoutes.settings),
              ),
              _buildMenuRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & FAQ',
                onTap: () => Get.toNamed(AppRoutes.helpFaq),
              ),
              const SizedBox(height: 24),
              _buildLogOutButton(),
              const SizedBox(height: 32),
              Text(
                'Version ${AppConstants.appVersion} • DriveSwap © 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required String fullName,
    required String email,
    required String initials,
    String? planTitle,
    bool loading = false,
  }) {
    final hasPlan = planTitle != null && planTitle.isNotEmpty;
    return Column(
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          )
        else ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.border.withValues(alpha: 0.6),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasPlan)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (hasPlan)
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.choosePlan),
              child: Text(
                planTitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.choosePlan),
              child: const Text(
                'Choose a plan',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 24, color: AppColors.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (trailing != null) const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.logoutRedBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            await UserPreferencesService.clearUserAndLoginState();
            await AuthService.signOut();
            Get.offAllNamed(AppRoutes.login);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 22, color: AppColors.logoutRed),
                const SizedBox(width: 10),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logoutRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.fullName,
    required this.email,
    required this.initials,
    this.planTitle,
  });
  final String fullName;
  final String email;
  final String initials;
  final String? planTitle;
}
