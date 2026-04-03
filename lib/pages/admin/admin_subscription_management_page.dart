import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/subscription_plan_service.dart';
import '../../core/theme/app_colors.dart';
import 'subscription/admin_plan_editor_page.dart';
import 'controllers/admin_subscription_management_controller.dart';

class AdminSubscriptionManagementPage
    extends GetView<AdminSubscriptionManagementController> {
  const AdminSubscriptionManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanEditor(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Plan'),
      ),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.loadPlans,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Text(
                  'Create, edit, and reorder subscription plans for the user side.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
               
                const SizedBox(height: 18),
                if (controller.hasError.value)
                  _InfoCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load plans',
                    subtitle: 'Pull to refresh and try again.',
                    color: AppColors.error,
                  )
                else if (controller.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.plans.isEmpty)
                  _InfoCard(
                    icon: Icons.card_membership_outlined,
                    title: 'No plans yet',
                    subtitle:
                        'Create your first subscription plan or load the default plan set.',
                    color: AppColors.textSecondary,
                  )
                else
                  ...controller.plans.map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanManagementCard(
                        plan: plan,
                        onEdit: () => _openPlanEditor(context, existing: plan),
                        onDelete: () => _confirmDelete(plan),
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

  Future<void> _confirmDelete(SubscriptionPlan plan) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('Remove "${plan.title}" from subscription plans?'),
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
      await controller.deletePlan(plan.id);
    }
  }

  Future<void> _openPlanEditor(
    BuildContext context, {
    SubscriptionPlan? existing,
  }) async {
    final result = await Get.to<SubscriptionPlan>(
      () => AdminPlanEditorPage(existing: existing),
    );
    if (result != null) {
      await controller.savePlan(result);
    }
  }
}

class _PlanManagementCard extends StatelessWidget {
  const _PlanManagementCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionPlan plan;
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(plan.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.price} • ${plan.durationLabel}',
                      style: TextStyle(
                        fontSize: 13,
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
                label: plan.isActive ? 'Active' : 'Inactive',
                color: plan.isActive ? AppColors.success : AppColors.warning,
              ),
              if (plan.popular)
                const _StatusChip(
                  label: 'Most Popular',
                  color: AppColors.primary,
                ),
              if (plan.savePercent != null)
                _StatusChip(
                  label: 'Save ${plan.savePercent}%',
                  color: AppColors.success,
                ),
              _StatusChip(
                label: 'Sort ${plan.sortOrder}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: plan.isGreenCheck
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
