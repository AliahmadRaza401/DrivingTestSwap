import 'package:get/get.dart';

import '../../../core/services/chat_service.dart';

class AdminMessagesController extends GetxController {
  final RxString query = ''.obs;
  final RxList<AdminConversationSummary> conversations =
      <AdminConversationSummary>[].obs;

  @override
  void onInit() {
    super.onInit();
    conversations.bindStream(ChatService.streamAllConversations());
  }

  void updateQuery(String value) {
    query.value = value.trim().toLowerCase();
  }

  List<AdminConversationSummary> get filteredConversations {
    final currentQuery = query.value;
    if (currentQuery.isEmpty) {
      return conversations;
    }
    return conversations.where((conversation) {
      return conversation.user1DisplayName.toLowerCase().contains(
            currentQuery,
          ) ||
          conversation.user2DisplayName.toLowerCase().contains(currentQuery) ||
          conversation.lastMessageText.toLowerCase().contains(currentQuery);
    }).toList();
  }
}
