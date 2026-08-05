import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String role; // 'user' or 'model'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, String> toHistoryMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] as String? ?? 'model',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, role, content, timestamp];
}

abstract class ChatbotState extends Equatable {
  final List<ChatMessage> messages;
  final bool isThinking;
  final String selectedModel;

  const ChatbotState({
    required this.messages,
    this.isThinking = false,
    this.selectedModel = 'gemini-2.5-flash',
  });

  @override
  List<Object?> get props => [messages, isThinking, selectedModel];
}

class ChatbotInitial extends ChatbotState {
  ChatbotInitial({super.selectedModel = 'gemini-2.5-flash'})
      : super(messages: [
          ChatMessage(
            id: 'welcome',
            role: 'model',
            content: 'Chào bạn! Tôi là BodyPilot AI Coach 🤖\n\nTôi có thể giúp bạn giải đáp mọi thắc mắc về thực đơn calo, bài tập fitness, tư vấn chấn thương hoặc cách sử dụng BodyPilot. Bạn cần hỗ trợ gì hôm nay?',
            timestamp: DateTime.now(),
          ),
        ]);
}

class ChatbotUpdated extends ChatbotState {
  const ChatbotUpdated({
    required super.messages,
    super.isThinking,
    super.selectedModel,
  });
}

class ChatbotError extends ChatbotState {
  final String errorMessage;

  const ChatbotError({
    required super.messages,
    required this.errorMessage,
    super.isThinking = false,
    super.selectedModel,
  });

  @override
  List<Object?> get props => [messages, isThinking, errorMessage, selectedModel];
}
