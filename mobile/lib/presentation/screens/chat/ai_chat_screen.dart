import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/presentation/bloc/chat/chatbot_cubit.dart';
import 'package:mobile/presentation/bloc/chat/chatbot_state.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickSuggestions = [
    '🥗 Tối nay tôi nên ăn món gì?',
    '🦵 Đau khớp gối nên tránh bài tập nào?',
    '📊 Chỉ số BMR và TDEE của tôi là bao nhiêu?',
    '💪 Muốn tăng cơ nhanh nên bổ sung Protein ra sao?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final query = presetText ?? _textController.text;
    if (query.trim().isEmpty) return;

    _textController.clear();
    context.read<ChatbotCubit>().sendMessage(query);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: BlocBuilder<ChatbotCubit, ChatbotState>(
          builder: (context, state) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BodyPilot AI Coach',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: () => _showModelSelectorBottomSheet(context, state.selectedModel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getModelLabel(state.selectedModel),
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: () => context.read<ChatbotCubit>().clearHistory(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA0AEC0), // Slate Grey
              Color(0xFFD6CCC2), // Warm Beige
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Chat List Area
              Expanded(
                child: BlocConsumer<ChatbotCubit, ChatbotState>(
                  listener: (context, state) {
                    _scrollToBottom();
                  },
                  builder: (context, state) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.messages.length + (state.isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length && state.isThinking) {
                          return _buildTypingIndicator();
                        }
                        final msg = state.messages[index];
                        return _buildChatBubble(msg);
                      },
                    );
                  },
                ),
              ),

              // Quick Suggestions Chips
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickSuggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = _quickSuggestions[index];
                    return ActionChip(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      label: Text(
                        suggestion,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _handleSend(suggestion),
                    );
                  },
                ),
              ),

              // Input Bar Area
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                color: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _textController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Hỏi AI Coach điều gì đó...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<ChatbotCubit, ChatbotState>(
                      builder: (context, state) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: state.isThinking
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: state.isThinking ? null : () => _handleSend(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: isUser ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AI Coach đang suy nghĩ', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModelLabel(String model) {
    switch (model) {
      case 'llama-3.1-8b-instant':
        return 'Llama 3.1 8B 🚀';
      case 'llama-3.3-70b-versatile':
        return 'Llama 3.3 70B ⚡';
      case 'gemini-2.5-flash':
      default:
        return 'Gemini 2.5 🤖';
    }
  }

  void _showModelSelectorBottomSheet(BuildContext context, String currentModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final models = [
          {
            'id': 'gemini-2.5-flash',
            'name': 'Gemini 2.5 Flash (Google)',
            'tag': '🤖 Mặc định',
            'desc': 'Trợ lý AI đa năng nổi tiếng của Google, tốc độ cao & hiểu ngữ cảnh xuất sắc.',
          },
          /* Cấu trúc Groq AI giữ lại để về sau tích hợp lại
          {
            'id': 'llama-3.1-8b-instant',
            'name': 'Llama 3.1 8B (Groq)',
            'tag': '🚀 Tốc độ cao',
            'desc': 'Phản hồi tức thì (~40ms), trả lời ngắn gọn, tiết kiệm thời gian.',
          },
          {
            'id': 'llama-3.3-70b-versatile',
            'name': 'Llama 3.3 70B (Groq)',
            'tag': '⚡ Thông minh',
            'desc': 'Mô hình mã nguồn mở mạnh mẽ cho câu hỏi chuyên sâu.',
          },
          */
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn Model AI Chatbot',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngữ cảnh cuộc trò chuyện sẽ được giữ nguyên khi thay đổi model.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: models.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = models[index];
                      final isSelected = item['id'] == currentModel;

                      return InkWell(
                        onTap: () {
                          context.read<ChatbotCubit>().changeModel(item['id']!);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primary : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item['name']!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? AppTheme.primary : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['tag']!,
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['desc']!,
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
