import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/moderation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';

/// Lets the user see who they have blocked and unblock them.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  Future<void> _unblock(String id, String name) async {
    try {
      await ModerationService.unblockUser(id);
      ToastUtil.success('$name has been unblocked.');
    } catch (e) {
      ToastUtil.error('Could not unblock. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<Set<String>>(
        stream: ModerationService.streamBlockedUserIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = (snapshot.data ?? <String>{}).toList();
          if (ids.isEmpty) {
            return _buildEmptyState();
          }
          return FutureBuilder<Map<String, String>>(
            future: ModerationService.fetchDisplayNames(ids),
            builder: (context, namesSnapshot) {
              final names = namesSnapshot.data ?? <String, String>{};
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: ids.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final id = ids[index];
                  final name = names[id] ?? 'User';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _unblock(id, name),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t blocked anyone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Blocked users\' posts and messages are hidden from you. You can block someone from any post or chat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
