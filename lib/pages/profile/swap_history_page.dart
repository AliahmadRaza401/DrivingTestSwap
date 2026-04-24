import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/post_service.dart';
import '../../core/services/swap_service.dart';
import '../../core/theme/app_colors.dart';

class SwapHistoryPage extends StatelessWidget {
  const SwapHistoryPage({super.key});

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Swap History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'Please log in to view swap history.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<List<SwapRecord>>(
              stream: SwapService.streamMySwaps(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load swap history.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final completedSwaps = snapshot.data!
                    .where((swap) => swap.isCompleted)
                    .toList();
                if (completedSwaps.isEmpty) {
                  return const Center(
                    child: Text(
                      'No completed swaps yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: completedSwaps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final swap = completedSwaps[index];
                    return _SwapHistoryCard(
                      record: swap,
                      currentUserId: currentUserId,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SwapHistoryCard extends StatelessWidget {
  const _SwapHistoryCard({required this.record, required this.currentUserId});

  final SwapRecord record;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SwapPost?>>(
      future: Future.wait([
        SwapService.getPostById(record.myPostId(currentUserId)),
        SwapService.getPostById(record.otherPostId(currentUserId)),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final myPost = snapshot.data?[0];
        final otherPost = snapshot.data?[1];
        final otherName = otherPost?.creatorName ?? 'another user';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed with $otherName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Completed on ${SwapHistoryPage._formatDate(record.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              if (myPost != null) ...[
                const SizedBox(height: 14),
                _HistorySlotCard(
                  title: 'Your original slot',
                  post: myPost,
                  color: AppColors.primary,
                ),
              ],
              if (otherPost != null) ...[
                const SizedBox(height: 12),
                _HistorySlotCard(
                  title: 'Swapped slot',
                  post: otherPost,
                  color: AppColors.success,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HistorySlotCard extends StatelessWidget {
  const _HistorySlotCard({
    required this.title,
    required this.post,
    required this.color,
  });

  final String title;
  final SwapPost post;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.testCentre,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${post.date} • ${post.time}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
