import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/post_service.dart';
import '../../core/services/swap_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
import '../../routes/app_routes.dart';
import '../chat/chat_page.dart';
import '../post_availability/post_availability_page.dart';

class NoticeboardPage extends StatefulWidget {
  const NoticeboardPage({super.key});

  @override
  State<NoticeboardPage> createState() => _NoticeboardPageState();
}

class _NoticeboardPageState extends State<NoticeboardPage> {
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
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('My Swap'),
                    const SizedBox(height: 10),
                    StreamBuilder<List<SwapRecord>>(
                      stream: SwapService.streamMySwaps(),
                      builder: (context, swapSnapshot) {
                        if (swapSnapshot.hasError) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Error loading swaps: ${swapSnapshot.error}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          );
                        }
                        final swaps = swapSnapshot.data ?? [];
                        if (swaps.isNotEmpty) {
                          final uid = AuthService.currentUser?.uid;
                          if (uid != null) {
                            return _MySwapResultCard(record: swaps.first, currentUserId: uid);
                          }
                        }
                        return StreamBuilder<List<SwapPost>>(
                          stream: PostService.streamMyPosts(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              final msg = PostService.userFriendlyPostError(snapshot.error!);
                              final indexUrl = PostService.getIndexCreationUrlFromError(snapshot.error!);
                              final isBuilding = PostService.isIndexBuildingError(snapshot.error!);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ToastUtil.error(msg);
                              });
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Error loading your post: $msg',
                                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                    if (indexUrl != null) ...[
                                      const SizedBox(height: 14),
                                      FilledButton.icon(
                                        onPressed: () => launchUrl(Uri.parse(indexUrl), mode: LaunchMode.externalApplication),
                                        icon: const Icon(Icons.open_in_new, size: 18),
                                        label: Text(isBuilding ? 'Check status' : 'Create index'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textOnPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                            final myPosts = snapshot.data ?? [];
                            final myPost = myPosts.isNotEmpty ? myPosts.first : null;
                            if (myPost == null) {
                              return _buildNoMyPostCard();
                            }
                            return _SwapCard(
                              initials: myPost.creatorInitials,
                              name: myPost.creatorName,
                              joined: 'Posted ${_timeAgo(myPost.createdAt)}',
                              location: myPost.testCentre,
                              distance: myPost.preferredArea.isNotEmpty ? myPost.preferredArea : null,
                              date: myPost.date,
                              time: myPost.time,
                              showSwapTag: false,
                              lookingFor: myPost.lookingFor.isNotEmpty ? myPost.lookingFor : null,
                              showActions: false,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Available for Swap'),
                    const SizedBox(height: 10),
                    StreamBuilder<List<SwapPost>>(
                      stream: PostService.streamOtherUsersPosts(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          final msg = PostService.userFriendlyPostError(snapshot.error!);
                          final indexUrl = PostService.getIndexCreationUrlFromError(snapshot.error!);
                          final isBuilding = PostService.isIndexBuildingError(snapshot.error!);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ToastUtil.error(msg);
                          });
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 40, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load posts: $msg',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                ),
                                if (indexUrl != null) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => launchUrl(Uri.parse(indexUrl), mode: LaunchMode.externalApplication),
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                    label: Text(isBuilding ? 'Check status' : 'Create index'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final posts = snapshot.data ?? [];
                        if (posts.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'No other swap posts yet. Check back later.',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            ...posts.map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SwapCard(
                                  initials: post.creatorInitials,
                                  name: post.creatorName,
                                  joined: 'Posted ${_timeAgo(post.createdAt)}',
                                  location: post.testCentre,
                                  distance: post.preferredArea.isNotEmpty ? post.preferredArea : null,
                                  date: post.date,
                                  time: post.time,
                                  showSwapTag: true,
                                  lookingFor: post.lookingFor,
                                  showActions: true,
                                  postForSwap: post,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMyPostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            'You have no active post',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Post your test availability so others can find you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.public_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Noticeboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  final hasSubscription = await AuthService.hasActiveSubscription();
                  if (hasSubscription) {
                    Get.to(() => const PostAvailabilityPage());
                  } else {
                    ToastUtil.info('Subscribe to add a post');
                    Get.toNamed(AppRoutes.choosePlan);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Post Availability'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

}

/// Shows the result of a completed swap: "Swapped with X – your new slot: date, time at centre."
class _MySwapResultCard extends StatelessWidget {
  const _MySwapResultCard({required this.record, required this.currentUserId});

  final SwapRecord record;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final otherPostId = record.otherPostId(currentUserId);
    return FutureBuilder<SwapPost?>(
      future: SwapService.getPostById(otherPostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final post = snapshot.data;
        if (post == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Your swap is saved. Post details could not be loaded.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.success, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Swapped with ${post.creatorName}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your new slot:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.testCentre,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(post.date, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(post.time, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({
    required this.initials,
    required this.name,
    required this.joined,
    required this.location,
    required this.distance,
    required this.date,
    required this.time,
    required this.showSwapTag,
    required this.lookingFor,
    required this.showActions,
    this.postForSwap,
  });

  final String initials;
  final String name;
  final String joined;
  final String location;
  final String? distance;
  final String date;
  final String time;
  final bool showSwapTag;
  final String? lookingFor;
  final bool showActions;
  /// When set, the Swap button navigates to the swap page with this post.
  final SwapPost? postForSwap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSwapTag)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.success, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Swap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          if (showSwapTag) const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  initials,
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
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      joined,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                location,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              if (distance != null) ...[
                Text(
                  ' ($distance)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (lookingFor != null) ...[
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Looking for: ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: lookingFor!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: postForSwap == null
                        ? null
                        : () async {
                            try {
                              final cid = await ChatService.getOrCreateConversation(
                                otherUserId: postForSwap!.userId,
                                otherDisplayName: postForSwap!.creatorName,
                                otherInitials: postForSwap!.creatorInitials,
                              );
                              if (context.mounted) {
                                Get.to(() => ChatPage(
                                  conversationId: cid,
                                  otherUserId: postForSwap!.userId,
                                  otherUserName: postForSwap!.creatorName,
                                  otherUserInitials: postForSwap!.creatorInitials,
                                ));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ToastUtil.error(e.toString());
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Connect & Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (postForSwap != null) {
                        Get.toNamed(AppRoutes.swap, arguments: postForSwap);
                      } else {
                        Get.toNamed(AppRoutes.swap);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Swap'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
