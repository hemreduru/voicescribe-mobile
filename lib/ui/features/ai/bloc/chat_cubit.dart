import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/repositories/chat_repository.dart';
import 'package:voicescribe_mobile/data/services/chat/local_chat_service.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';

class ChatState {
  const ChatState({
    this.sessionId,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.errorMessage,
  });

  final int? sessionId;
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? errorMessage;

  ChatState copyWith({
    int? sessionId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// Drives a single conversation. [lastTouchedSessionId] lets the parent list
/// refresh after a send creates/updates a session.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._repository, {
    LocalChatService? localChat,
    TranscriptRepository? transcriptRepository,
  })  : _localChat = localChat,
        _transcriptRepository = transcriptRepository,
        super(const ChatState());

  final ChatRepository _repository;
  final LocalChatService? _localChat;
  final TranscriptRepository? _transcriptRepository;

  int? lastTouchedSessionId;

  /// True when the user's AI provider preference is on-device and the local
  /// engine is wired in.
  Future<bool> _useLocal() async {
    if (_localChat == null || _transcriptRepository == null) {
      return false;
    }
    try {
      final prefs = (await _transcriptRepository.loadSnapshot()).preferences;
      return prefs.summaryProvider == 'local';
    } catch (_) {
      return false;
    }
  }

  Future<void> openExisting(int id) async {
    emit(ChatState(sessionId: id, loading: true));
    try {
      final session = await _repository.getSession(id);
      emit(ChatState(sessionId: id, messages: session.messages));
    } on ChatException catch (e) {
      emit(ChatState(sessionId: id, errorMessage: e.message));
    } catch (_) {
      emit(ChatState(sessionId: id, errorMessage: 'Sohbet yüklenemedi.'));
    }
  }

  void startNew() => emit(const ChatState());

  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty || state.sending) {
      return;
    }

    // Optimistic: show the user's message immediately + a thinking indicator.
    final optimistic = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(
      messages: [...state.messages, optimistic],
      sending: true,
      clearError: true,
    ));

    if (await _useLocal()) {
      await _sendLocal(text, optimistic);
      return;
    }

    try {
      final result = await _repository.sendMessage(
        sessionId: state.sessionId,
        content: text,
      );
      lastTouchedSessionId = result.session.id;
      final reconciled = [
        ...state.messages.where((m) => m.id != optimistic.id),
        result.userMessage,
        result.assistantMessage,
      ];
      emit(state.copyWith(
        sessionId: result.session.id,
        messages: reconciled,
        sending: false,
      ));
    } on ChatException catch (e) {
      emit(state.copyWith(sending: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        sending: false,
        errorMessage: 'Yanıt alınamadı. Lütfen tekrar dene.',
      ));
    }
  }

  /// On-device RAG answer (no backend session — kept in-memory for this
  /// conversation). [optimistic] is the already-shown user message.
  Future<void> _sendLocal(String text, ChatMessage optimistic) async {
    final history = state.messages.where((m) => m.id != optimistic.id).toList();
    try {
      final result = await _localChat!.answer(question: text, history: history);
      final now = DateTime.now();
      final userMessage = ChatMessage(
        id: optimistic.id,
        role: 'user',
        content: text,
        createdAt: now,
      );
      final assistantMessage = ChatMessage(
        id: -now.microsecondsSinceEpoch,
        role: 'assistant',
        content: result.answer,
        sources: result.sources,
        createdAt: now.add(const Duration(milliseconds: 1)),
      );
      emit(state.copyWith(
        messages: [
          ...state.messages.where((m) => m.id != optimistic.id),
          userMessage,
          assistantMessage,
        ],
        sending: false,
      ));
    } on LocalChatException catch (e) {
      emit(state.copyWith(sending: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        sending: false,
        errorMessage: 'Yanıt alınamadı. Lütfen tekrar dene.',
      ));
    }
  }
}
