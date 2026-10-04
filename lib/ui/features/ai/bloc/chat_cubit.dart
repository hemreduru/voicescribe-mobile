import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/repositories/chat_repository.dart';
import 'package:voicescribe_mobile/domain/models/app_error.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';

class ChatState {
  const ChatState({
    this.sessionId,
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.errorCode,
    this.errorMessage,
  });

  final int? sessionId;
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;

  /// Machine-readable failure mapped to the active locale by the UI. When
  /// null, [errorMessage] (e.g. a server-provided message) is shown raw.
  final AppErrorCode? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null || errorMessage != null;

  ChatState copyWith({
    int? sessionId,
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    AppErrorCode? errorCode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// Drives a single conversation. [lastTouchedSessionId] lets the parent list
/// refresh after a send creates/updates a session.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatState());

  final ChatRepository _repository;

  int? lastTouchedSessionId;

  Future<void> openExisting(int id) async {
    emit(ChatState(sessionId: id, loading: true));
    try {
      final session = await _repository.getSession(id);
      emit(ChatState(sessionId: id, messages: session.messages));
    } on ChatException catch (e) {
      emit(ChatState(sessionId: id, errorMessage: e.message));
    } catch (_) {
      emit(ChatState(sessionId: id, errorCode: AppErrorCode.chatLoadFailed));
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
    emit(
      state.copyWith(
        messages: [...state.messages, optimistic],
        sending: true,
        clearError: true,
      ),
    );

    await _sendCloudStreaming(text, optimistic);
  }

  /// Cloud answer over SSE: renders the reply as it streams. Falls back to the
  /// buffered endpoint only when streaming fails **before** the server persisted
  /// the user message (`meta`), so we never duplicate it.
  Future<void> _sendCloudStreaming(String text, ChatMessage optimistic) async {
    final base = state.messages.where((m) => m.id != optimistic.id).toList();
    var gotMeta = false;
    var userMessage = optimistic;
    final buffer = StringBuffer();
    final assistantId = -DateTime.now().microsecondsSinceEpoch;
    var assistant = ChatMessage(
      id: assistantId,
      role: 'assistant',
      createdAt: DateTime.now(),
    );

    try {
      await for (final ev in _repository.streamMessage(
        content: text,
        sessionId: state.sessionId,
      )) {
        switch (ev.type) {
          case 'meta':
            gotMeta = true;
            final session = _session(ev.data?['session']);
            if (session != null) lastTouchedSessionId = session.id;
            final um = _message(ev.data?['user_message']);
            if (um != null) userMessage = um;
            emit(
              state.copyWith(
                sessionId: session?.id ?? state.sessionId,
                messages: [...base, userMessage, assistant],
                sending: true,
              ),
            );
          case 'delta':
            final t = ev.data?['text'];
            if (t is String && t.isNotEmpty) {
              buffer.write(t);
              assistant = assistant.copyWith(content: buffer.toString());
              emit(state.copyWith(messages: [...base, userMessage, assistant]));
            }
          case 'done':
            final session = _session(ev.data?['session']);
            if (session != null) lastTouchedSessionId = session.id;
            final finalAssistant =
                _message(ev.data?['assistant_message']) ??
                assistant.copyWith(content: buffer.toString());
            emit(
              state.copyWith(
                sessionId: session?.id ?? state.sessionId,
                messages: [...base, userMessage, finalAssistant],
                sending: false,
              ),
            );
            return;
          case 'error':
            throw ChatException(
              ev.data?['message']?.toString() ?? 'Akış hatası.',
            );
        }
      }
      // Stream ended without a `done` event — settle whatever we have.
      emit(state.copyWith(sending: false));
    } on ChatException catch (e) {
      if (!gotMeta) {
        await _sendCloudBatch(text, optimistic);
        return;
      }
      emit(state.copyWith(sending: false, errorMessage: e.message));
    } catch (_) {
      if (!gotMeta) {
        await _sendCloudBatch(text, optimistic);
        return;
      }
      emit(
        state.copyWith(sending: false, errorCode: AppErrorCode.chatSendFailed),
      );
    }
  }

  /// Buffered cloud send (the original non-streaming path), used as the fallback.
  Future<void> _sendCloudBatch(String text, ChatMessage optimistic) async {
    try {
      final result = await _repository.sendMessage(
        sessionId: state.sessionId,
        content: text,
      );
      lastTouchedSessionId = result.session.id;
      final base = state.messages.where((m) => m.id != optimistic.id).toList();
      emit(
        state.copyWith(
          sessionId: result.session.id,
          messages: [...base, result.userMessage, result.assistantMessage],
          sending: false,
        ),
      );
    } on ChatException catch (e) {
      emit(state.copyWith(sending: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(sending: false, errorCode: AppErrorCode.chatSendFailed),
      );
    }
  }
  ChatSession? _session(Object? raw) {
    if (raw is! Map) return null;
    try {
      return ChatSession.fromJson(raw.map((k, v) => MapEntry(k.toString(), v)));
    } catch (_) {
      return null;
    }
  }

  ChatMessage? _message(Object? raw) {
    if (raw is! Map) return null;
    try {
      return ChatMessage.fromJson(raw.map((k, v) => MapEntry(k.toString(), v)));
    } catch (_) {
      return null;
    }
  }
}
