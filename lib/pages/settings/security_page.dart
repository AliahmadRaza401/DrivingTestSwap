import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

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
          'Security',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tip(
              Icons.lock_rounded,
              'Strong password',
              'Use a unique password for this app with at least 6 characters. Change it regularly from Settings > Change Password.',
            ),
            _tip(
              Icons.phone_android_rounded,
              'Secure your device',
              'Keep your phone locked and do not share your login details with anyone. Log out if you use the app on a shared device.',
            ),
            _tip(
              Icons.swap_horiz_rounded,
              'Swap safely',
              'Complete test date changes only on the official GOV.UK website. Never share your DVSA booking password or pay anyone to swap for you.',
            ),
            _tip(
              Icons.chat_bubble_outline_rounded,
              'Messages',
              'Do not send sensitive personal or payment details in chat. We do not ask for your password or card details in the app.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _tip(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
