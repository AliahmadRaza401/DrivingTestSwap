import 'package:flutter/material.dart';

import '../../core/services/moderation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';

/// Admin view of user reports and blocks. Lets the developer review flagged
/// content, remove it, and mark reports as handled (App Store Guideline 1.2:
/// act on objectionable-content reports within 24 hours).
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  Future<void> _remove(ModerationReport report) async {
    try {
      await ModerationService.removeReportedContent(report);
      ToastUtil.success('Content removed and report closed.');
    } catch (e) {
      ToastUtil.error('Could not remove content. Please try again.');
    }
  }

  Future<void> _markReviewed(ModerationReport report) async {
    try {
      await ModerationService.updateReportStatus(
        report.id,
        FirestoreReports.statusReviewed,
      );
      ToastUtil.success('Marked as reviewed.');
    } catch (e) {
      ToastUtil.error('Could not update the report. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(76, 20, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reports & Blocks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ModerationReport>>(
                stream: ModerationService.streamReports(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load reports: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No reports yet. Reports and blocks from users will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: reports.length,
                    itemBuilder: (context, index) =>
                        _ReportCard(
                      report: reports[index],
                      onRemove: () => _remove(reports[index]),
                      onMarkReviewed: () => _markReviewed(reports[index]),
                    ),
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onRemove,
    required this.onMarkReviewed,
  });

  final ModerationReport report;
  final VoidCallback onRemove;
  final VoidCallback onMarkReviewed;

  Color get _statusColor {
    switch (report.status) {
      case FirestoreReports.statusRemoved:
        return AppColors.success;
      case FirestoreReports.statusReviewed:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRemovableContent =
        report.contentId.isNotEmpty || report.conversationId.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.isBlock ? Icons.block : Icons.flag_outlined,
                size: 20,
                color: report.isBlock ? AppColors.error : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.isBlock
                      ? 'User blocked'
                      : 'Reported ${report.contentType}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Reason', report.reason),
          if (report.details.isNotEmpty) _row('Details', report.details),
          _row(
            'Reported user',
            report.reportedUserName.isNotEmpty
                ? '${report.reportedUserName} (${report.reportedUserId})'
                : report.reportedUserId,
          ),
          _row(
            'Reported by',
            report.reporterEmail.isNotEmpty
                ? report.reporterEmail
                : report.reporterId,
          ),
          if (report.contentText.isNotEmpty) _row('Content', report.contentText),
          _row('When', AdminReportsPage._formatDate(report.createdAt)),
          if (report.status != FirestoreReports.statusRemoved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasRemovableContent)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: const Text('Remove content'),
                    ),
                  ),
                if (hasRemovableContent) const SizedBox(width: 10),
                if (report.isPending)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onMarkReviewed,
                      icon: const Icon(Icons.check, size: 18),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: const Text('Mark reviewed'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
