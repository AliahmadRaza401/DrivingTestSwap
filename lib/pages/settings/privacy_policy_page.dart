import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
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
            _section('Last updated', 'This policy applies to the DriveSwap app and describes how we collect, use and protect your information.'),
            _section('Information we collect', 'We collect the information you provide when you register (email, name, date of birth) and when you post test availability (test centre, date, time, preferences). We use Firebase for authentication and Firestore for storing your profile and posts.'),
            _section('How we use it', 'Your information is used to run the app: to show your profile, to match you with other learners for swaps, and to manage your subscription. We do not sell your data to third parties.'),
            _section('Data security', 'We use industry-standard services (Firebase/Google) to store data. Your password is never stored in plain text. Keep your login details secure.'),
            _section('Your rights', 'You can request access to or deletion of your data by contacting us. You can delete your account and data from within the app (e.g. via Settings or by contacting support).'),
            _section('Contact', 'For privacy questions or requests, contact us via the support details in the app.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
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
    );
  }
}
