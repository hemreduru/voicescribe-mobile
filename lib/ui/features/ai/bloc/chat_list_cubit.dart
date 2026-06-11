import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/data/repositories/chat_repository.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';

class ChatListState {
  const ChatListState({
    this.sessions = const [],
    this.loading = false,
    this.errorMessage,
  });

  final List<ChatSession> sessions;
  final bool loading;
  final String? errorMessage;

  ChatListState copyWith({
    List<ChatSession>? sessions,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatListState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this._repository) : super(const ChatListState());

  final ChatRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final sessions = await _repository.listSessions();
      emit(state.copyWith(sessions: sessions, loading: false));
    } on ChatException catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(loading: false, errorMessage: 'Sohbetler yüklenemedi.'),
      );
    }
  }

  Future<void> delete(int id) async {
    // Optimistic removal.
    final previous = state.sessions;
    emit(
      state.copyWith(
        sessions: previous.where((s) => s.id != id).toList(growable: false),
      ),
    );
    try {
      await _repository.deleteSession(id);
    } catch (_) {
      emit(
        state.copyWith(sessions: previous, errorMessage: 'Sohbet silinemedi.'),
      );
    }
  }
}
