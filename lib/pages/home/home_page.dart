import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/toast_util.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GetX structure is ready.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ToastUtil.success('Success toast'),
              child: const Text('Show success toast'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ToastUtil.error('Error toast'),
              child: const Text('Show error toast'),
            ),
          ],
        ),
      ),
    );
  }
}
