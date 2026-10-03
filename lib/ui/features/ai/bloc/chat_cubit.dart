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
      emit(
        state.copyWith(
          sessionId: result.session.id,
          messages: reconciled,
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
}
