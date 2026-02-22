import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/post_service.dart';
import '../../core/services/swap_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
import '../../routes/app_routes.dart';
import '../main/controllers/main_controller.dart';
import '../post_availability/post_availability_page.dart';

class SwapPage extends StatefulWidget {
  const SwapPage({super.key});

  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  /// Other user's post to swap with (passed from Noticeboard when user taps Swap).
  SwapPost? _selectedTargetPost;
  /// Current user's post to give (selected from list at bottom).
  SwapPost? _selectedMyPost;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SwapPost) _selectedTargetPost = args;
  }

  static String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _performSwap() async {
    if (_selectedTargetPost == null || _selectedMyPost == null) return;
    final target = _selectedTargetPost!;
    final my = _selectedMyPost!;
    final confirm = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: AppColors.success, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Confirm swap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(my.testCentre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('${my.date} • ${my.time}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Icon(Icons.swap_vert_rounded, color: AppColors.success, size: 24),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 20, color: AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${target.creatorName}\'s test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(target.testCentre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('${target.date} • ${target.time}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm swap'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await SwapService.createSwap(
        myPostId: my.id,
        targetUserId: target.userId,
        targetPostId: target.id,
      );
      ToastUtil.success('Swap completed');
      Get.offAllNamed(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<MainController>()) {
          Get.find<MainController>().setIndex(0);
        }
      });
    } catch (e) {
      ToastUtil.error(e.toString());
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Swap',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post to swap with',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildTopTargetCard(),
            const SizedBox(height: 20),
            _buildSwapIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Your post',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMyPostsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTargetCard() {
    if (_selectedTargetPost != null) {
      final post = _selectedTargetPost!;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
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
                        'Posted ${_timeAgo(post.createdAt)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.testCentre,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(post.date, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(width: 16),
                Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(post.time, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
            if (post.lookingFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Looking for: ${post.lookingFor}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Go to the Noticeboard and tap Swap on a post to swap with that slot.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSwapIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swap_vert_rounded, color: AppColors.success, size: 28),
        const SizedBox(width: 8),
        Text(
          'Swap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMyPostsSection() {
    return StreamBuilder<List<SwapPost>>(
      stream: PostService.streamMyPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Error: ${PostService.userFriendlyPostError(snapshot.error!)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final myPosts = snapshot.data ?? [];
        if (myPosts.isEmpty) {
          return _buildAddPostCard();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...myPosts.map((post) => _buildMyPostTile(post)),
            const SizedBox(height: 24),
            _buildSwapButton(),
          ],
        );
      },
    );
  }

  Widget _buildMyPostTile(SwapPost post) {
    final isSelected = _selectedMyPost?.id == post.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedMyPost = isSelected ? null : post),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<SwapPost>(
                  value: post,
                  groupValue: _selectedMyPost,
                  onChanged: (p) => setState(() => _selectedMyPost = p),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.testCentre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.date} • ${post.time}',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (post.lookingFor.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Looking for: ${post.lookingFor}',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwapButton() {
    final canSwap = _selectedTargetPost != null && _selectedMyPost != null;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canSwap ? _performSwap : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(canSwap ? 'Swap' : 'Select both posts above to swap'),
      ),
    );
  }

  Widget _buildAddPostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _openAddPost,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final hasSubscription = await AuthService.hasActiveSubscription();
                if (hasSubscription) {
                  Get.to(() => const PostAvailabilityPage());
                } else {
                  ToastUtil.info('Subscribe to add a post');
                  Get.toNamed(AppRoutes.choosePlan);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Post'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPost() async {
    final hasSubscription = await AuthService.hasActiveSubscription();
    if (hasSubscription) {
      Get.to(() => const PostAvailabilityPage());
    } else {
      ToastUtil.info('Subscribe to add a post');
      Get.toNamed(AppRoutes.choosePlan);
    }
  }
}
