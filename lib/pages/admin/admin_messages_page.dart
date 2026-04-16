import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../chat/chat_page.dart';
import 'controllers/admin_messages_controller.dart';

class AdminMessagesPage extends GetView<AdminMessagesController> {
  const AdminMessagesPage({super.key});

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          final list = controller.filteredConversations;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Messages',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View all user conversations from the admin panel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: controller.updateQuery,
                      decoration: InputDecoration(
                        hintText: 'Search chats by user or message',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            controller.query.value.isEmpty
                                ? 'No conversations found yet.'
                                : 'No matching conversations found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final conversation = list[index];
                          return _AdminConversationTile(
                            conversation: conversation,
                            onTap: () => Get.to(
                              () => ChatPage(
                                conversationId: conversation.conversationId,
                                otherUserId: conversation.user2Id,
                                otherUserName:
                                    '${conversation.user1DisplayName} & ${conversation.user2DisplayName}',
                                otherUserInitials: conversation.user1Initials,
                                readOnlyMode: true,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AdminConversationTile extends StatelessWidget {
  const _AdminConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final AdminConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        '${conversation.user1DisplayName}  •  ${conversation.user2DisplayName}';
    final subtitle = conversation.lastMessageText.isEmpty
        ? 'No messages yet'
        : conversation.lastMessageText;
    final initials =
        '${conversation.user1Initials}${conversation.user2Initials}'.trim();
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withValues(alpha: 0.14),
        child: Text(
          initials.isEmpty ? 'CH' : initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      trailing: Text(
        AdminMessagesPage._formatTime(conversation.lastMessageAt),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
