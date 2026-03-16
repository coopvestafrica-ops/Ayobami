import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
import 'package:ayobami/core/voice/voice_controller.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/chat/chat_event.dart';
import 'package:ayobami/presentation/bloc/chat/chat_state.dart';
import 'package:ayobami/presentation/widgets/chat_bubble.dart';
import 'package:ayobami/presentation/widgets/voice_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc;
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    _voiceController = di.sl<VoiceController>();
    _chatBloc = ChatBloc(
      getChatHistory: di.sl(),
      sendMessage: di.sl(),
      saveUserMemory: di.sl(),
      getUserMemory: di.sl(),
      voiceController: _voiceController,
    );
    _chatBloc.add(const LoadChatHistoryEvent());
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceController.initialize();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _chatBloc.add(SendMessageEvent(text));
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

  void _startListening() {
    _chatBloc.add(const StartVoiceListeningEvent());
  }

  void _stopListening() {
    _chatBloc.add(const StopVoiceListeningEvent());
  }

  void _speakResponse(String text) {
    _chatBloc.add(SpeakResponseEvent(text));
  }

  void _stopSpeaking() {
    _chatBloc.add(const StopSpeakingEvent());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.close();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ayobami'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to settings
              },
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
                            : () => _speakResponse(message.content),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _sendMessage,
                          ),
                          VoiceButton(
                            isListening: state.voiceStatus == VoiceStatus.listening,
                            onPressed: state.voiceStatus == VoiceStatus.listening
                                ? _stopListening
                                : _startListening,
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
      ),
    );
  }
}
