import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/admin_service.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/admin_tests_controller.dart';

class AdminTestsPage extends GetView<AdminTestsController> {
  const AdminTestsPage({super.key});

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
                  'Tests Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review active test posts and completed swap records.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _TestsTabBar(
                  selectedIndex: controller.selectedTabIndex.value,
                  onSelected: controller.setTabIndex,
                ),
                const SizedBox(height: 18),
                if (controller.hasError.value)
                  const _TestsEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load tests data',
                    subtitle: 'Pull to refresh and try again.',
                  )
                else if (controller.isLoading.value ||
                    controller.testsOverview.value == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.68,
                    child: controller.selectedTabIndex.value == 0
                        ? _PostsTab(
                            posts: controller.testsOverview.value!.posts,
                            onDelete: controller.deletePost,
                          )
                        : _SwapsTab(
                            runningSwaps:
                                controller.testsOverview.value!.runningSwaps,
                            completedSwaps:
                                controller.testsOverview.value!.completedSwaps,
                            onDelete: controller.deleteSwap,
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

class _TestsTabBar extends StatelessWidget {
  const _TestsTabBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Posts',
              isSelected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabButton(
              label: 'Swaps',
              isSelected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts, required this.onDelete});

  final List<AdminSwapPostRecord> posts;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _TestsEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No test posts',
        subtitle: 'New test posts will appear here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (item.post.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${item.post.notes}',
                    style: TextStyle(
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

class _SwapsTab extends StatelessWidget {
  const _SwapsTab({
    required this.runningSwaps,
    required this.completedSwaps,
    required this.onDelete,
  });

  final List<AdminSwapRecord> runningSwaps;
  final List<AdminSwapRecord> completedSwaps;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (runningSwaps.isEmpty && completedSwaps.isEmpty) {
      return const _TestsEmptyState(
        icon: Icons.swap_horizontal_circle_outlined,
        title: 'No swaps found',
        subtitle: 'Running and completed swaps will appear here.',
      );
    }

    final sections = <Widget>[
      if (runningSwaps.isNotEmpty) ...[
        const _SectionTitle(
          title: 'Running swaps',
          subtitle: 'Swaps that are still active or in progress.',
        ),
        const SizedBox(height: 12),
        ...List.generate(
          runningSwaps.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SwapCard(
              item: runningSwaps[index],
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
              onDelete: onDelete,
              accentColor: AppColors.warning,
              iconColor: AppColors.warning,
            ),
          ),
        ),
      ],
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: sections,
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({
    required this.item,
    required this.onDelete,
    required this.accentColor,
    required this.iconColor,
  });

  final AdminSwapRecord item;
  final Future<void> Function(String id) onDelete;
  final Color accentColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = item.swap.status.trim().isEmpty
        ? 'unknown'
        : item.swap.status;
    final isCompleted = normalizedStatus.toLowerCase() == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Completed swap' : 'Running swap',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Initiator: ${item.initiatorEmail.isEmpty ? item.swap.initiatorUserId : item.initiatorEmail}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${item.targetEmail.isEmpty ? item.swap.targetUserId : item.targetEmail}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $normalizedStatus',
                  style: TextStyle(
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
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

class _TestsEmptyState extends StatelessWidget {
  const _TestsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
