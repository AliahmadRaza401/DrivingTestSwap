import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/location_service.dart';
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
  CurrentLocationData? _currentLocation;
  String? _locationError;
  bool _loadingLocation = false;
  bool _loadingRadius = false;
  bool _distanceFilterEnabled = false;
  double _selectedDistanceFilter = 20;
  Timer? _radiusLoadingTimer;
  final Set<String> _completingSwapIds = <String>{};

  static String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _radiusLoadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
        _loadingLocation = false;
      });
    }
  }

  void _onRadiusChanged(double value) {
    _radiusLoadingTimer?.cancel();
    setState(() {
      _selectedDistanceFilter = value;
      _loadingRadius = true;
    });

    _radiusLoadingTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _loadingRadius = false;
      });
    });
  }

  void _onDistanceFilterToggled(bool enabled) {
    if (enabled && _currentLocation == null) return;
    _radiusLoadingTimer?.cancel();
    setState(() {
      _distanceFilterEnabled = enabled;
      _loadingRadius = enabled;
    });

    if (!enabled) {
      setState(() {
        _loadingRadius = false;
      });
      return;
    }

    _radiusLoadingTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _loadingRadius = false;
      });
    });
  }

  Future<void> _completeSwap(SwapRecord record) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Complete swap?'),
        content: const Text(
          'Use this only after both users have finished the real DVSA test-date change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _completingSwapIds.add(record.id);
    });

    try {
      await SwapService.completeSwap(record.id);
      ToastUtil.success('Swap marked as completed');
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _completingSwapIds.remove(record.id);
        });
      }
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('My Swap'),
                    const SizedBox(height: 10),
                    _buildMySwapsSection(),
                    const SizedBox(height: 24),
                    _sectionTitle('Available for Swap'),
                    const SizedBox(height: 10),
                    _buildDistanceHeader(),
                    const SizedBox(height: 12),
                    StreamBuilder<List<SwapPost>>(
                      stream: PostService.streamOtherUsersPosts(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          final msg = PostService.userFriendlyPostError(
                            snapshot.error!,
                          );
                          final indexUrl =
                              PostService.getIndexCreationUrlFromError(
                                snapshot.error!,
                              );
                          final isBuilding = PostService.isIndexBuildingError(
                            snapshot.error!,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ToastUtil.error(msg);
                          });
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load posts: $msg',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (indexUrl != null) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => launchUrl(
                                      Uri.parse(indexUrl),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isBuilding
                                          ? 'Check status'
                                          : 'Create index',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (_loadingRadius) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Loading nearest test centres...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final posts = snapshot.data ?? [];
                        final visiblePosts = _sortedAndFilteredPosts(posts);
                        if (visiblePosts.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              posts.isEmpty
                                  ? 'No other swap posts yet. Check back later.'
                                  : _distanceFilterEnabled
                                  ? 'No posts match the selected distance filter.'
                                  : 'No posts available right now.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            ...visiblePosts.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SwapCard(
                                  initials: item.post.creatorInitials,
                                  name: item.post.creatorName,
                                  joined:
                                      'Posted ${_timeAgo(item.post.createdAt)}',
                                  location: item.post.testCentre,
                                  distance: item.distanceMiles == null
                                      ? null
                                      : LocationService.formatDistanceMiles(
                                          item.distanceMiles!,
                                        ),
                                  date: item.post.date,
                                  time: item.post.time,
                                  showSwapTag: true,
                                  lookingFor: item.post.lookingFor,
                                  preferredArea:
                                      item.post.preferredArea.isNotEmpty
                                      ? item.post.preferredArea
                                      : null,
                                  showActions: true,
                                  postForSwap: item.post,
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
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'You have no active post',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
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

  Widget _buildMySwapsSection() {
    return StreamBuilder<List<SwapRecord>>(
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }

        final swaps = swapSnapshot.data ?? [];
        final currentUserId = AuthService.currentUser?.uid;
        if (swaps.isNotEmpty && currentUserId != null) {
          final inProgressSwaps = swaps
              .where((swap) => swap.isInProgress)
              .toList();

          if (inProgressSwaps.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSwapSectionHeader(
                  title: 'In Progress',
                  subtitle:
                      'Finish the DVSA change, then complete the swap here.',
                  count: inProgressSwaps.length,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 10),
                ...inProgressSwaps.map(
                  (swap) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MySwapRecordCard(
                      record: swap,
                      currentUserId: currentUserId,
                      isCompleting: _completingSwapIds.contains(swap.id),
                      onComplete: () => _completeSwap(swap),
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return StreamBuilder<List<SwapPost>>(
          stream: PostService.streamMyPosts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final msg = PostService.userFriendlyPostError(snapshot.error!);
              final indexUrl = PostService.getIndexCreationUrlFromError(
                snapshot.error!,
              );
              final isBuilding = PostService.isIndexBuildingError(
                snapshot.error!,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ToastUtil.error(msg);
              });
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error loading your post: $msg',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (indexUrl != null) ...[
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(indexUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(
                          isBuilding ? 'Check status' : 'Create index',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
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
              distance: _currentLocation != null && myPost.hasTestCentreLocation
                  ? LocationService.formatDistanceMiles(
                      LocationService.distanceInMiles(
                        fromLatitude: _currentLocation!.latitude,
                        fromLongitude: _currentLocation!.longitude,
                        toLatitude: myPost.testCentreLat!,
                        toLongitude: myPost.testCentreLng!,
                      ),
                    )
                  : null,
              date: myPost.date,
              time: myPost.time,
              showSwapTag: false,
              lookingFor: myPost.lookingFor.isNotEmpty
                  ? myPost.lookingFor
                  : null,
              preferredArea: myPost.preferredArea.isNotEmpty
                  ? myPost.preferredArea
                  : null,
              showActions: false,
            );
          },
        );
      },
    );
  }

  Widget _buildSwapSectionHeader({
    required String title,
    required String subtitle,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
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
                child: Icon(
                  Icons.public_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
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
                  final hasSubscription =
                      await AuthService.hasActiveSubscription();
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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

  List<_PostWithDistance> _sortedAndFilteredPosts(List<SwapPost> posts) {
    final items = posts.map((post) {
      final location = _currentLocation;
      final hasLocation = location != null && post.hasTestCentreLocation;
      final distanceMiles = hasLocation
          ? LocationService.distanceInMiles(
              fromLatitude: location.latitude,
              fromLongitude: location.longitude,
              toLatitude: post.testCentreLat!,
              toLongitude: post.testCentreLng!,
            )
          : null;
      return _PostWithDistance(post: post, distanceMiles: distanceMiles);
    }).toList();

    items.sort((a, b) {
      final aDistance = a.distanceMiles;
      final bDistance = b.distanceMiles;
      if (aDistance == null && bDistance == null) {
        return b.post.createdAt.compareTo(a.post.createdAt);
      }
      if (aDistance == null) return 1;
      if (bDistance == null) return -1;
      final compareDistance = aDistance.compareTo(bDistance);
      if (compareDistance != 0) return compareDistance;
      return b.post.createdAt.compareTo(a.post.createdAt);
    });

    if (!_distanceFilterEnabled) {
      return items;
    }

    final filter = _selectedDistanceFilter;
    return items
        .where(
          (item) => item.distanceMiles != null && item.distanceMiles! <= filter,
        )
        .toList();
  }

  Widget _buildDistanceHeader() {
    final currentLocation = _currentLocation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _loadingLocation
                      ? 'Finding your location...'
                      : _locationError != null
                      ? _locationError!
                      : currentLocation != null
                      ? 'Nearest posts first'
                      : 'Enable location for nearby sorting.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadingLocation ? null : _loadCurrentLocation,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
                tooltip: 'Refresh location',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (currentLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _distanceFilterEnabled ? 'Nearby on' : 'Nearby off',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _distanceFilterEnabled,
                  onChanged: _loadingLocation ? null : _onDistanceFilterToggled,
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
          if (_loadingLocation || _loadingRadius) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (currentLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '0 mi',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _selectedDistanceFilter,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_selectedDistanceFilter.round()} mi',
                    onChanged: _distanceFilterEnabled ? _onRadiusChanged : null,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 54),
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_selectedDistanceFilter.round()} mi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _distanceFilterEnabled
                  ? 'Only posts within your selected distance are shown.'
                  : 'All posts are shown.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ] else if (_locationError == null && !_loadingLocation) ...[
            const SizedBox(height: 4),
            const Text(
              'Turn on location to use nearby filtering.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostWithDistance {
  const _PostWithDistance({required this.post, required this.distanceMiles});

  final SwapPost post;
  final double? distanceMiles;
}

class _MySwapRecordCard extends StatelessWidget {
  const _MySwapRecordCard({
    required this.record,
    required this.currentUserId,
    this.isCompleting = false,
    this.onComplete,
  });

  final SwapRecord record;
  final String currentUserId;
  final bool isCompleting;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final otherPostId = record.otherPostId(currentUserId);
    final myPostId = record.myPostId(currentUserId);
    return FutureBuilder<List<SwapPost?>>(
      future: Future.wait([
        SwapService.getPostById(myPostId),
        SwapService.getPostById(otherPostId),
      ]),
      builder: (context, postsSnapshot) {
        if (postsSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final myPost = postsSnapshot.data?[0];
        final otherPost = postsSnapshot.data?[1];
        if (myPost == null && otherPost == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'This swap is saved, but the related post details could not be loaded.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }

        final isCompleted = record.isCompleted;
        final statusColor = isCompleted ? AppColors.success : AppColors.warning;
        final otherName = otherPost?.creatorName ?? 'another user';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swap with $otherName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'In progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isCompleted
                    ? 'You can review the finished swap details below.'
                    : 'Complete the DVSA change first, then mark this swap as completed.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (myPost != null) ...[
                const SizedBox(height: 14),
                _SwapSlotSummary(
                  title: 'Your original slot',
                  icon: Icons.person_outline_rounded,
                  color: AppColors.primary,
                  post: myPost,
                ),
              ],
              if (otherPost != null) ...[
                const SizedBox(height: 12),
                _SwapSlotSummary(
                  title: isCompleted ? 'Swapped slot' : 'Requested slot',
                  icon: Icons.flag_outlined,
                  color: statusColor,
                  post: otherPost,
                ),
              ],
              if (!isCompleted) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isCompleting ? null : onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCompleting ? 'Completing...' : 'Complete swap',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SwapSlotSummary extends StatelessWidget {
  const _SwapSlotSummary({
    required this.title,
    required this.icon,
    required this.color,
    required this.post,
  });

  final String title;
  final IconData icon;
  final Color color;
  final SwapPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
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
    required this.preferredArea,
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
  final String? preferredArea;
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
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 6),
                Text(
                  distance!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
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
          if (preferredArea != null) ...[
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Preferred area: ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: preferredArea!,
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
                              final cid =
                                  await ChatService.getOrCreateConversation(
                                    otherUserId: postForSwap!.userId,
                                    otherDisplayName: postForSwap!.creatorName,
                                    otherInitials: postForSwap!.creatorInitials,
                                  );
                              if (context.mounted) {
                                Get.to(
                                  () => ChatPage(
                                    conversationId: cid,
                                    otherUserId: postForSwap!.userId,
                                    otherUserName: postForSwap!.creatorName,
                                    otherUserInitials:
                                        postForSwap!.creatorInitials,
                                  ),
                                );
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
