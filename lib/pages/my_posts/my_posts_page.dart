import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
import '../post_availability/post_availability_page.dart';

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  static String _errorMessage(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s;
  }

  static String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Posts',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recent Posts',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<SwapPost>>(
                stream: PostService.streamMyPosts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    developer.log('MyPosts stream error', name: 'MyPostsPage', error: snapshot.error, stackTrace: snapshot.stackTrace);
                    final msg = PostService.userFriendlyPostError(snapshot.error!);
                    final indexUrl = PostService.getIndexCreationUrlFromError(snapshot.error!);
                    final isBuilding = PostService.isIndexBuildingError(snapshot.error!);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ToastUtil.error(msg);
                    });
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              isBuilding ? 'Index building' : 'Failed to load posts',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            if (indexUrl != null) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => launchUrl(Uri.parse(indexUrl), mode: LaunchMode.externalApplication),
                                icon: const Icon(Icons.open_in_new, size: 20),
                                label: Text(isBuilding ? 'Check status' : 'Create index'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textOnPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Post your test availability to the noticeboard so others can swap with you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _PostCard(
                        post: post,
                        timeAgo: _timeAgo(post.createdAt),
                        onEdit: () async {
                          try {
                            final result = await Get.to<bool>(() => PostAvailabilityPage(editPost: post));
                            if (result == true) ToastUtil.success('Post updated');
                          } catch (e, st) {
                            developer.log('Edit post failed', name: 'MyPostsPage', error: e, stackTrace: st);
                            ToastUtil.error(_errorMessage(e));
                          }
                        },
                        onDelete: () async {
                          final confirm = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Delete post?'),
                              content: const Text('This post will be removed from the noticeboard.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await PostService.deletePost(post.id);
                              ToastUtil.success('Post deleted');
                            } catch (e, st) {
                              developer.log('Delete post failed', name: 'MyPostsPage', error: e, stackTrace: st);
                              ToastUtil.error(_errorMessage(e));
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.timeAgo,
    required this.onEdit,
    required this.onDelete,
  });

  final SwapPost post;
  final String timeAgo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final location = post.testCentre;
    final distance = post.preferredArea.isNotEmpty ? post.preferredArea : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  post.creatorInitials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.creatorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Posted $timeAgo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              if (distance != null)
                Text(
                  '($distance)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                post.date,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                post.time,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (post.lookingFor.isNotEmpty) ...[
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Looking for: ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: post.lookingFor,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
