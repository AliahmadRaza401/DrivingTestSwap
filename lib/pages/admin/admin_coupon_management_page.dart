import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/coupon_service.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/admin_coupon_management_controller.dart';
import 'subscription/admin_coupon_editor_page.dart';

class AdminCouponManagementPage
    extends GetView<AdminCouponManagementController> {
  const AdminCouponManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Coupon Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.loadCoupons,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _SectionHeader(
                  title: 'Coupons',
                  subtitle:
                      'Create fixed discount coupons and share the generated codes with users.',
                  actionLabel: 'Add Coupon',
                  icon: Icons.confirmation_number_rounded,
                  onPressed: () => _openCouponEditor(context),
                ),
                const SizedBox(height: 16),
                if (controller.hasError.value)
                  const _InfoCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load coupons',
                    subtitle: 'Pull to refresh and try again.',
                    color: AppColors.error,
                  )
                else if (controller.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.coupons.isEmpty)
                  const _InfoCard(
                    icon: Icons.sell_outlined,
                    title: 'No coupons yet',
                    subtitle:
                        'Create a coupon code so users can apply a discount during purchase.',
                    color: AppColors.textSecondary,
                  )
                else
                  ...controller.coupons.map(
                    (coupon) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CouponManagementCard(
                        coupon: coupon,
                        onEdit: () =>
                            _openCouponEditor(context, existing: coupon),
                        onDelete: () => _confirmDeleteCoupon(coupon),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCoupon(CouponRecord coupon) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('Remove coupon code "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteCoupon(coupon.code);
    }
  }

  Future<void> _openCouponEditor(
    BuildContext context, {
    CouponRecord? existing,
  }) async {
    final result = await Get.to<CouponRecord>(
      () => AdminCouponEditorPage(existing: existing),
    );
    if (result != null) {
      await controller.saveCoupon(result);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _CouponManagementCard extends StatelessWidget {
  const _CouponManagementCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final CouponRecord coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sell_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.code,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: coupon.isActive ? 'Active' : 'Inactive',
                color: coupon.isActive ? AppColors.success : AppColors.warning,
              ),
              _StatusChip(
                label: 'Discount ${coupon.formattedDiscount}',
                color: AppColors.primary,
              ),
              _StatusChip(
                label: 'Used ${coupon.usageCount}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: color),
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
