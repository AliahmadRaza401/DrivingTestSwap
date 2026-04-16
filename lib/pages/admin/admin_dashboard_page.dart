import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/admin_service.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/admin_dashboard_controller.dart';

class AdminDashboardPage extends GetView<AdminDashboardController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Admin Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor users, swaps, revenue and platform activity in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (controller.hasError.value)
                  _ErrorState(onRetry: controller.loadDashboard)
                else if (controller.isLoading.value ||
                    controller.stats.value == null)
                  const _DashboardShimmer()
                else ...[
                  _HeroCard(stats: controller.stats.value!),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final aspectRatio = width < 360 ? 0.88 : 1.02;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: aspectRatio,
                        children: [
                          _StatCard(
                            label: 'Total Users',
                            value: '${controller.stats.value!.totalUsers}',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF2563EB),
                          ),
                          _StatCard(
                            label: 'Total Posts',
                            value: '${controller.stats.value!.totalPosts}',
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF0F766E),
                          ),
                          _StatCard(
                            label: 'Total Test Swap',
                            value: '${controller.stats.value!.totalSwaps}',
                            icon: Icons.swap_horiz_rounded,
                            color: const Color(0xFFD97706),
                          ),
                          _StatCard(
                            label: 'Total Earning',
                            value: controller.currency(
                              controller.stats.value!.totalEarnings,
                            ),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF7C3AED),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _ActivityChartCard(
                    activity: controller.stats.value!.activity,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final AdminDashboardStats stats;

  String _currency(double value) => '£${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final todayEarnings = (stats.todayEarnings as num?)?.toDouble() ?? 0;
    final todaySwaps = (stats.todaySwaps as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today earning ${_currency(todayEarnings)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today test swap: $todaySwaps',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChartCard extends StatelessWidget {
  const _ActivityChartCard({required this.activity});

  final List<AdminActivityPoint> activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 days activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Graphical view of new users, new posts, and completed swaps.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: CustomPaint(
              painter: _ActivityChartPainter(activity),
              child: Container(),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _LegendDot(color: Color(0xFF2563EB), label: 'Users'),
              _LegendDot(color: Color(0xFF0F766E), label: 'Posts'),
              _LegendDot(color: Color(0xFFD97706), label: 'Swaps'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  _ActivityChartPainter(this.activity);

  final List<AdminActivityPoint> activity;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 12.0;
    const bottomPadding = 28.0;
    const leftPadding = 8.0;
    const rightPadding = 8.0;

    final chartHeight = size.height - topPadding - bottomPadding;
    final barGroupWidth =
        (size.width - leftPadding - rightPadding) /
        math.max(activity.length, 1);
    final maxValue = activity.fold<int>(
      1,
      (max, point) => math.max(
        max,
        math.max(point.users, math.max(point.posts, point.swaps)),
      ),
    );

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    for (var i = 0; i < activity.length; i++) {
      final point = activity[i];
      final baseX = leftPadding + (barGroupWidth * i) + 6;
      final baseY = size.height - bottomPadding;
      final barWidth = math.min(10.0, (barGroupWidth - 10) / 3);

      _drawBar(
        canvas,
        baseX,
        baseY,
        chartHeight,
        maxValue,
        point.users,
        barWidth,
        const Color(0xFF2563EB),
      );
      _drawBar(
        canvas,
        baseX + barWidth + 4,
        baseY,
        chartHeight,
        maxValue,
        point.posts,
        barWidth,
        const Color(0xFF0F766E),
      );
      _drawBar(
        canvas,
        baseX + ((barWidth + 4) * 2),
        baseY,
        chartHeight,
        maxValue,
        point.swaps,
        barWidth,
        const Color(0xFFD97706),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barGroupWidth);
      textPainter.paint(canvas, Offset(baseX - 2, size.height - 18));
    }
  }

  void _drawBar(
    Canvas canvas,
    double left,
    double baseY,
    double chartHeight,
    int maxValue,
    int value,
    double width,
    Color color,
  ) {
    final safeValue = value <= 0 ? 0.04 : value / maxValue;
    final height = chartHeight * safeValue;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, baseY - height, width, height),
      const Radius.circular(6),
    );
    final paint = Paint()..color = color;
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.activity != activity;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Unable to load dashboard data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or tap retry.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          const _ShimmerBox(height: 148, radius: 24),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.02,
            children: const [
              _ShimmerBox(height: 152, radius: 22),
              _ShimmerBox(height: 152, radius: 22),
              _ShimmerBox(height: 152, radius: 22),
              _ShimmerBox(height: 152, radius: 22),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 190, height: 20, radius: 10),
                SizedBox(height: 8),
                _ShimmerBox(width: 260, height: 14, radius: 8),
                SizedBox(height: 18),
                _ShimmerBox(height: 210, radius: 20),
                SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _ShimmerBox(width: 74, height: 12, radius: 999),
                    _ShimmerBox(width: 72, height: 12, radius: 999),
                    _ShimmerBox(width: 76, height: 12, radius: 999),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPosition = (_controller.value * 2) - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.6 + shimmerPosition, -0.2),
              end: Alignment(1.6 + shimmerPosition, 0.2),
              colors: const [
                Color(0xFFE5EAF1),
                Color(0xFFF5F7FB),
                Color(0xFFE5EAF1),
              ],
              stops: const [0.1, 0.45, 0.9],
            ),
          ),
        );
      },
    );
  }
}
