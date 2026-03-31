import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/domain/usecases/chat/get_chat_history.dart';
import 'package:ayobami/domain/usecases/chat/send_message.dart';
import 'package:ayobami/domain/usecases/settings/user_memory_use_cases.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/core/voice/voice_controller.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatHistory getChatHistory;
  final SendMessage sendMessage;
  final SaveUserMemory saveUserMemory;
  final GetUserMemory getUserMemory;
  final VoiceController? voiceController;

  ChatBloc({
    required this.getChatHistory,
    required this.sendMessage,
    required this.saveUserMemory,
    required this.getUserMemory,
    this.voiceController,
  }) : super(const ChatState()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<StartVoiceListeningEvent>(_onStartVoiceListening);
    on<StopVoiceListeningEvent>(_onStopVoiceListening);
    on<VoiceResultEvent>(_onVoiceResult);
    on<SpeakResponseEvent>(_onSpeakResponse);
    on<StopSpeakingEvent>(_onStopSpeaking);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final messages = await getChatHistory();
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final response = await sendMessage(event.message);
      final messages = List<ChatMessage>.from(state.messages);
      
      // Add user message
      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
      // Add AI response (sendMessage returns a ChatMessage)
      messages.add(response);
      
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onClearChat(
    ClearChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      status: ChatStatus.success,
      messages: [],
    ));
  }

  Future<void> _onStartVoiceListening(
    StartVoiceListeningEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (voiceController == null) return;

    emit(state.copyWith(voiceStatus: VoiceStatus.listening));

    await voiceController!.startListening(
      onResult: (text) {
        add(VoiceResultEvent(text));
      },
      onError: (error) {
        emit(state.copyWith(
          voiceStatus: VoiceStatus.idle,
          errorMessage: error,
        ));
      },
    );
  }

  Future<void> _onStopVoiceListening(
    StopVoiceListeningEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (voiceController == null) return;
    
    await voiceController!.stopListening();
    emit(state.copyWith(voiceStatus: VoiceStatus.idle));
  }

  Future<void> _onVoiceResult(
    VoiceResultEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      voiceStatus: VoiceStatus.idle,
      recognizedText: event.text,
    ));
    
    // Automatically send the message
    add(SendMessageEvent(event.text));
  }

  Future<void> _onSpeakResponse(
    SpeakResponseEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (voiceController == null) return;

    emit(state.copyWith(isSpeaking: true, voiceStatus: VoiceStatus.speaking));
    await voiceController!.speak(event.text);
    emit(state.copyWith(isSpeaking: false, voiceStatus: VoiceStatus.idle));
  }

  Future<void> _onStopSpeaking(
    StopSpeakingEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (voiceController == null) return;

    await voiceController!.stopSpeaking();
    emit(state.copyWith(isSpeaking: false, voiceStatus: VoiceStatus.idle));
  }

  @override
  Future<void> close() {
    voiceController?.dispose();
    return super.close();
  }
}
