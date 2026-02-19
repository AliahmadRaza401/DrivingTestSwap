import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';

/// Toast / Snackbar helper using GetX.
abstract class ToastUtil {
  ToastUtil._();

  static void success(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title ?? 'Success',
      message,
      backgroundColor: AppColors.success.withValues(alpha: 0.95),
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
    );
  }

  static void error(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title ?? 'Error',
      message,
      backgroundColor: AppColors.error.withValues(alpha: 0.95),
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white, size: 28),
    );
  }

  static void warning(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title ?? 'Warning',
      message,
      backgroundColor: AppColors.warning.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.warning_amber, color: Colors.white, size: 28),
    );
  }

  static void info(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title ?? 'Info',
      message,
      backgroundColor: AppColors.info.withValues(alpha: 0.95),
      colorText: AppColors.textOnPrimary,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.info, color: Colors.white, size: 28),
    );
  }

  static void show(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    Get.snackbar(
      title ?? '',
      message,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      snackPosition: position,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
