import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final isLoggedIn = await UserPreferencesService.isLoggedIn();
    final role = await UserPreferencesService.role;
    final hasAuthUser = AuthService.currentUser != null;

    if (isLoggedIn && role == UserPrefsKeys.roleAdmin) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.adminHome);
      return;
    }

    if (isLoggedIn && role != UserPrefsKeys.roleAdmin && hasAuthUser) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    if (isLoggedIn && role != UserPrefsKeys.roleAdmin && !hasAuthUser) {
      await UserPreferencesService.clearUserAndLoginState();
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Image.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            width: 220,
            height: 220,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.directions_car_rounded,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
