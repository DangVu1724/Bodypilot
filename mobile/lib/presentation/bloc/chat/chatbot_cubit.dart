import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  ChatbotCubit() : super(ChatbotInitial()) {
    loadHistory();
  }

  void loadHistory() {
    final userId = TokenService.getUserId();
    if (userId != null) {
      final savedMaps = TokenService.getChatHistory(userId);
      if (savedMaps.isNotEmpty) {
        final messages = savedMaps.map((m) => ChatMessage.fromJson(m)).toList();
        emit(ChatbotUpdated(messages: messages, isThinking: false));
      }
    }
  }

  Future<void> _saveCurrentHistory(List<ChatMessage> messages) async {
    final userId = TokenService.getUserId();
    if (userId != null) {
      final jsonList = messages.map((m) => m.toJson()).toList();
      await TokenService.saveChatHistory(userId, jsonList);
    }
  }

  String _cleanReply(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```(?:json)?\s*'), '').replaceAll(RegExp(r'\s*```$'), '').trim();
    }
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final map = jsonDecode(text) as Map<String, dynamic>;
        for (final key in ['response', 'reply', 'message', 'content', 'text']) {
          if (map.containsKey(key) && map[key] is String) {
            return map[key] as String;
          }
        }
      } catch (_) {}
    }
    return text;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isThinking) return;

    final userId = TokenService.getUserId();
    if (userId == null) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMsg);

    emit(ChatbotUpdated(messages: updatedMessages, isThinking: true));

    try {
      // Build history of last 6 messages
      final history = updatedMessages
          .take(updatedMessages.length - 1)
          .map((m) => m.toHistoryMap())
          .toList();

      final res = await userRepository.sendChatMessage(userId, trimmed, history);
      final rawReply = res['reply'] as String? ?? 'Tôi đã nhận được câu hỏi của bạn!';
      final replyText = _cleanReply(rawReply);

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'model',
        content: replyText,
        timestamp: DateTime.now(),
      );

      final finalMessages = List<ChatMessage>.from(updatedMessages)..add(aiMsg);
      emit(ChatbotUpdated(messages: finalMessages, isThinking: false));
      await _saveCurrentHistory(finalMessages);
    } catch (e) {
      print("🚨 [ChatbotCubit Error]: $e");
      final errorAiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'model',
        content: 'Xin lỗi bạn, tôi gặp sự cố kết nối nhỏ. Bạn vui lòng thử lại câu hỏi nhé!',
        timestamp: DateTime.now(),
      );
      final errorMessages = List<ChatMessage>.from(updatedMessages)..add(errorAiMsg);
      emit(ChatbotError(
        messages: errorMessages,
        errorMessage: e.toString(),
        isThinking: false,
      ));
      await _saveCurrentHistory(errorMessages);
    }
  }

  Future<void> clearHistory() async {
    final userId = TokenService.getUserId();
    if (userId != null) {
      await TokenService.clearChatHistory(userId);
    }
    emit(ChatbotInitial());
  }
}
