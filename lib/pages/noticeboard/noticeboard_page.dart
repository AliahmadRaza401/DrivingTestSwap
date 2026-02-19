import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class NoticeboardPage extends StatefulWidget {
  const NoticeboardPage({super.key});

  @override
  State<NoticeboardPage> createState() => _NoticeboardPageState();
}

class _NoticeboardPageState extends State<NoticeboardPage> {
  int _filterIndex = 0; // 0 = Nearest, 1 = My Preferences

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
                    _buildMySwapCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('Available for Swap'),
                    const SizedBox(height: 10),
                    _buildAvailableCard(
                      initials: 'Sa',
                      name: 'Sarah J.',
                      joined: 'Joined Jan 2026 · 2h ago',
                      location: 'Birmingham (South Yardley)',
                      distance: '4.2 miles away',
                      date: '10 Mar',
                      time: '09:15',
                      lookingFor: 'Any date in April',
                    ),
                    const SizedBox(height: 12),
                    _buildAvailableCard(
                      initials: 'Mi',
                      name: 'Mike T.',
                      joined: 'Joined Feb 2026 · 5h ago',
                      location: 'Birmingham (Kings Heath)',
                      distance: null,
                      date: '28 Feb',
                      time: '14:30',
                      lookingFor: 'Earlier dates only',
                    ),
                    const SizedBox(height: 12),
                    _buildAvailableCard(
                      initials: 'Em',
                      name: 'Emma W.',
                      joined: 'Joined Dec 2025 · 1d ago',
                      location: 'Sutton Coldfield',
                      distance: '8.5 miles away',
                      date: '5 Mar',
                      time: '11:45',
                      lookingFor: 'Kings Heath area preferred',
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
                onPressed: () {},
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
          const SizedBox(height: 14),
          Row(
            children: [
              _filterPill('Nearest', _filterIndex == 0, () => setState(() => _filterIndex = 0)),
              const SizedBox(width: 10),
              _filterPill('My Preferences', _filterIndex == 1, () => setState(() => _filterIndex = 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
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

  Widget _buildMySwapCard() {
    return _SwapCard(
      initials: 'A',
      name: 'Alex',
      joined: 'Joined Jan 2026 · 2h ago',
      location: 'Birmingham (South Yardley)',
      distance: '4.2 miles away',
      date: '10 Mar',
      time: '09:15',
      showSwapTag: false,
      lookingFor: null,
      showActions: false,
    );
  }

  Widget _buildAvailableCard({
    required String initials,
    required String name,
    required String joined,
    required String location,
    required String? distance,
    required String date,
    required String time,
    required String lookingFor,
  }) {
    return _SwapCard(
      initials: initials,
      name: name,
      joined: joined,
      location: location,
      distance: distance,
      date: date,
      time: time,
      showSwapTag: true,
      lookingFor: lookingFor,
      showActions: true,
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
                    onPressed: () {},
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
                    onPressed: () => Get.toNamed(AppRoutes.swap),
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
