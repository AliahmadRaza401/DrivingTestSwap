import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/admin_service.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/admin_tests_controller.dart';

class AdminPostsPage extends GetView<AdminTestsController> {
  const AdminPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.loadTests,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Posts Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review every test post added by users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                if (controller.hasError.value)
                  const _AdminEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load posts',
                    subtitle: 'Pull to refresh and try again.',
                  )
                else if (controller.isLoading.value ||
                    controller.testsOverview.value == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _PostsList(
                    posts: controller.testsOverview.value!.posts,
                    onDelete: controller.deletePost,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts, required this.onDelete});

  final List<AdminSwapPostRecord> posts;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _AdminEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No test posts',
        subtitle: 'All added test posts will appear here.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = posts[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.post.testCentre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onDelete(item.post.id),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MetaTag(
                    label: 'Owner',
                    value: item.ownerName.isEmpty
                        ? item.ownerEmail
                        : item.ownerName,
                  ),
                  _MetaTag(
                    label: 'Email',
                    value: item.ownerEmail.isEmpty ? 'N/A' : item.ownerEmail,
                  ),
                  _MetaTag(label: 'Date', value: item.post.date),
                  _MetaTag(label: 'Time', value: item.post.time),
                  _MetaTag(label: 'Looking for', value: item.post.lookingFor),
                ],
              ),
              if (item.post.preferredArea.isNotEmpty ||
                  item.post.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (item.post.preferredArea.isNotEmpty)
                  Text(
                    'Preferred area: ${item.post.preferredArea}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (item.post.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${item.post.notes}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
