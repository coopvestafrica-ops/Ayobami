import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
import 'package:ayobami/core/voice/voice_controller.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/chat/chat_event.dart';
import 'package:ayobami/presentation/bloc/chat/chat_state.dart';
import 'package:ayobami/presentation/widgets/chat_bubble.dart';
import 'package:ayobami/presentation/widgets/voice_button.dart';
import 'package:ayobami/presentation/pages/exchange_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    _voiceController = di.sl<VoiceController>();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceController.initialize();
  }

  void _sendMessage(ChatBloc chatBloc) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      chatBloc.add(SendMessageEvent(text));
      _messageController.clear();
      _scrollToBottom();
    }
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

  void _startListening(ChatBloc chatBloc) {
    chatBloc.add(const StartVoiceListeningEvent());
  }

  void _stopListening(ChatBloc chatBloc) {
    chatBloc.add(const StopVoiceListeningEvent());
  }

  void _speakResponse(ChatBloc chatBloc, String text) {
    chatBloc.add(SpeakResponseEvent(text));
  }

  void _stopSpeaking(ChatBloc chatBloc) {
    chatBloc.add(const StopSpeakingEvent());
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExchangeSettingsPage(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final chatBloc = context.read<ChatBloc>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ayobami'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _navigateToSettings,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state.status == ChatStatus.success) {
                      _scrollToBottom();
                    }
                  },
                  builder: (context, state) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Say something or type a message...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return ChatBubble(
                          message: message.content,
                          isUser: message.isUser,
                          onSpeak: message.isUser
                              ? null
                              : () => _speakResponse(chatBloc, message.content),
                        );
                      },
                    );
                  },
                ),
              ),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Column(
                      children: [
                        if (state.voiceStatus == VoiceStatus.listening)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Listening...'),
                              ],
                            ),
                          ),
                        if (state.isSpeaking)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.volume_up, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Speaking...'),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(chatBloc),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _sendMessage(chatBloc),
                            ),
                            VoiceButton(
                              isListening: state.voiceStatus == VoiceStatus.listening,
                              onPressed: state.voiceStatus == VoiceStatus.listening
                                  ? () => _stopListening(chatBloc)
                                  : () => _startListening(chatBloc),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
