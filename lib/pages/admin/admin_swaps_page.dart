import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/admin_service.dart';
import '../../core/services/post_service.dart';
import '../../core/services/swap_service.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/admin_tests_controller.dart';

class AdminSwapsPage extends GetView<AdminTestsController> {
  const AdminSwapsPage({super.key});

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
                  'Swaps Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review all swap records, including in-progress and completed swaps.',
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
                    title: 'Unable to load swaps',
                    subtitle: 'Pull to refresh and try again.',
                  )
                else if (controller.isLoading.value ||
                    controller.testsOverview.value == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _SwapsList(
                    runningSwaps: controller.testsOverview.value!.runningSwaps,
                    completedSwaps:
                        controller.testsOverview.value!.completedSwaps,
                    onComplete: controller.completeSwap,
                    onDelete: controller.deleteSwap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwapsList extends StatelessWidget {
  const _SwapsList({
    required this.runningSwaps,
    required this.completedSwaps,
    required this.onComplete,
    required this.onDelete,
  });

  final List<AdminSwapRecord> runningSwaps;
  final List<AdminSwapRecord> completedSwaps;
  final Future<void> Function(String id) onComplete;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (runningSwaps.isEmpty && completedSwaps.isEmpty) {
      return const _AdminEmptyState(
        icon: Icons.swap_horizontal_circle_outlined,
        title: 'No swaps found',
        subtitle: 'All swap records will appear here.',
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (runningSwaps.isNotEmpty) ...[
          const _SectionTitle(
            title: 'In Progress swaps',
            subtitle: 'Swaps that still need to be completed by the users.',
          ),
          const SizedBox(height: 12),
          ...List.generate(
            runningSwaps.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SwapCard(
                item: runningSwaps[index],
                onComplete: onComplete,
                onDelete: onDelete,
                accentColor: AppColors.primary,
                iconColor: AppColors.primary,
              ),
            ),
          ),
        ],
        if (runningSwaps.isNotEmpty && completedSwaps.isNotEmpty)
          const SizedBox(height: 8),
        if (completedSwaps.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Completed swaps',
            subtitle: 'Finished swap records.',
          ),
          const SizedBox(height: 12),
          ...List.generate(
            completedSwaps.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == completedSwaps.length - 1 ? 0 : 12,
              ),
              child: _SwapCard(
                item: completedSwaps[index],
                onComplete: onComplete,
                onDelete: onDelete,
                accentColor: AppColors.warning,
                iconColor: AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({
    required this.item,
    required this.onComplete,
    required this.onDelete,
    required this.accentColor,
    required this.iconColor,
  });

  final AdminSwapRecord item;
  final Future<void> Function(String id) onComplete;
  final Future<void> Function(String id) onDelete;
  final Color accentColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = item.swap.normalizedStatus;
    final isCompleted = item.swap.isCompleted;
    final statusLabel = normalizedStatus == FirestoreSwaps.statusInProgress
        ? 'In progress'
        : normalizedStatus == FirestoreSwaps.statusCompleted
        ? 'Completed'
        : normalizedStatus.replaceAll('_', ' ');

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.swap_horiz_rounded, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Completed swap' : 'In progress swap',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $statusLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onDelete(item.swap.id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ParticipantCard(
            label: 'Initiator',
            color: AppColors.primary,
            name: item.initiatorName,
            email: item.initiatorEmail,
            userId: item.swap.initiatorUserId,
            post: item.initiatorPost,
          ),
          const SizedBox(height: 12),
          _ParticipantCard(
            label: 'Target',
            color: accentColor,
            name: item.targetName,
            email: item.targetEmail,
            userId: item.swap.targetUserId,
            post: item.targetPost,
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => onComplete(item.swap.id),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Complete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.label,
    required this.color,
    required this.name,
    required this.email,
    required this.userId,
    required this.post,
  });

  final String label;
  final Color color;
  final String? name;
  final String? email;
  final String? userId;
  final SwapPost? post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (name ?? '').isEmpty ? 'Unknown user' : name!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (email ?? '').isEmpty ? (userId ?? 'Unknown ID') : email!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (post != null) ...[
            _InfoRow(label: 'Test centre', value: post!.testCentre),
            _InfoRow(label: 'Date', value: post!.date),
            _InfoRow(label: 'Time', value: post!.time),
            if (post!.lookingFor.isNotEmpty)
              _InfoRow(label: 'Looking for', value: post!.lookingFor),
            if (post!.preferredArea.isNotEmpty)
              _InfoRow(label: 'Preferred area', value: post!.preferredArea),
            if (post!.notes.isNotEmpty)
              _InfoRow(label: 'Notes', value: post!.notes),
          ] else
            const Text(
              'Post details not available.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
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
