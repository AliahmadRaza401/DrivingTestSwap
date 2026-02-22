import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../chat/chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<ConversationSummary>>(
        stream: ChatService.streamMyConversations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error!;
            final stackTrace = snapshot.stackTrace;
            developer.log(
              'MessagesPage: failed to load conversations',
              name: 'MessagesPage',
              error: error,
              stackTrace: stackTrace,
            );
            if (kDebugMode) {
              debugPrint('[MessagesPage] ERROR: $error');
              if (stackTrace != null) debugPrint('[MessagesPage] StackTrace: $stackTrace');
            }
            final msg = ChatService.userFriendlyChatError(error);
            final indexUrl = ChatService.getIndexCreationUrlFromError(error);
            final isBuilding = ChatService.isIndexBuildingError(error);
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (indexUrl != null) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => launchUrl(Uri.parse(indexUrl), mode: LaunchMode.externalApplication),
                          icon: const Icon(Icons.open_in_new, size: 18),
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
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No conversations yet.\nTap "Connect & Message" on a noticeboard post to start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final c = list[index];
              return _ConversationTile(
                name: c.otherDisplayName,
                initials: c.otherInitials,
                lastMessage: c.lastMessageText.isEmpty ? 'No messages yet' : c.lastMessageText,
                time: _formatTime(c.lastMessageAt),
                onTap: () => Get.to(() => ChatPage(
                  conversationId: c.conversationId,
                  otherUserId: c.otherUserId,
                  otherUserName: c.otherDisplayName,
                  otherUserInitials: c.otherInitials,
                )),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.time,
    required this.onTap,
  });

  final String name;
  final String initials;
  final String lastMessage;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      trailing: time.isNotEmpty
          ? Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
    );
  }
}
