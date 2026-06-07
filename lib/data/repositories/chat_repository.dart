import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';

/// Thrown when a chat operation fails; [message] is user-facing (Turkish).
class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => 'ChatException: $message';
}

/// Result of sending a chat message: the (possibly newly created) session plus
/// the persisted user and assistant messages.
class ChatSendResult {
  const ChatSendResult({
    required this.session,
    required this.userMessage,
    required this.assistantMessage,
  });

  final ChatSession session;
  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
}

class ChatRepository {
  ChatRepository({
    required TranscriptApiClient apiClient,
    required String? Function() tokenProvider,
  }) : _apiClient = apiClient,
       _tokenProvider = tokenProvider;

  final TranscriptApiClient _apiClient;
  final String? Function() _tokenProvider;

  String _token() {
    final token = _tokenProvider()?.trim();
    if (token == null || token.isEmpty) {
      throw const ChatException('Bu özellik için giriş yapmış olmanız gerekiyor.');
    }
    return token;
  }

  Future<List<ChatSession>> listSessions() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/api/v1/chat/sessions',
      token: _token(),
    );
    _ensureSuccess(response);
    final data = response.data;
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<Object?, Object?>>()
        .map((item) => ChatSession.fromJson(_stringKeyed(item)))
        .toList(growable: false);
  }

  Future<ChatSession> getSession(int id) async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/api/v1/chat/sessions/$id',
      token: _token(),
    );
    _ensureSuccess(response);
    final data = response.data;
    if (data is! Map) {
      throw const ChatException('Sohbet yüklenemedi.');
    }
    return ChatSession.fromJson(_stringKeyed(data));
  }

  Future<ChatSendResult> sendMessage({
    required String content,
    int? sessionId,
  }) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/api/v1/chat/messages',
      payload: <String, Object?>{
        if (sessionId != null) 'session_id': sessionId,
        'content': content,
      },
      token: _token(),
      readTimeout: const Duration(seconds: 60),
    );
    if (!response.isSuccess) {
      if (response.isNetworkFailure) {
        throw const ChatException(
          'Bağlantı yok. İnternet bağlantını kontrol edip tekrar dene.',
        );
      }
      throw ChatException(
        response.message ?? 'Yapay zekâ şu an yanıt veremedi. Lütfen tekrar dene.',
      );
    }
    final data = response.data;
    if (data is! Map) {
      throw const ChatException('Geçersiz sunucu yanıtı.');
    }
    final map = _stringKeyed(data);
    return ChatSendResult(
      session: ChatSession.fromJson(
        _stringKeyed(map['session'] as Map<Object?, Object?>),
      ),
      userMessage: ChatMessage.fromJson(
        _stringKeyed(map['user_message'] as Map<Object?, Object?>),
      ),
      assistantMessage: ChatMessage.fromJson(
        _stringKeyed(map['assistant_message'] as Map<Object?, Object?>),
      ),
    );
  }

  Future<void> deleteSession(int id) async {
    final response = await _apiClient.request(
      method: 'DELETE',
      path: '/api/v1/chat/sessions/$id',
      token: _token(),
    );
    _ensureSuccess(response);
  }

  void _ensureSuccess(ApiResponse response) {
    if (response.isSuccess) {
      return;
    }
    if (response.isNetworkFailure) {
      throw const ChatException('Bağlantı yok. Daha sonra tekrar dene.');
    }
    throw ChatException(response.message ?? 'İşlem başarısız oldu.');
  }

  Map<String, dynamic> _stringKeyed(Map<Object?, Object?> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}
