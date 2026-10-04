import 'dart:convert';

import 'package:voicescribe_mobile/data/services/transcript_api_client.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';

/// One parsed Server-Sent Event from the streaming chat endpoint. [type] is the
/// SSE `event:` name (`meta` / `delta` / `done` / `error`); [data] is the parsed
/// JSON payload (null when the payload wasn't valid JSON).
class ChatStreamEvent {
  const ChatStreamEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic>? data;
}

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
      throw const ChatException(
        'Bu özellik için giriş yapmış olmanız gerekiyor.',
      );
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
        response.message ??
            'Yapay zekâ şu an yanıt veremedi. Lütfen tekrar dene.',
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

  /// Streaming variant of [sendMessage] over Server-Sent Events. Yields a `meta`
  /// event (session + persisted user message + sources), then `delta` events as
  /// the answer is generated, then a `done` event with the saved assistant
  /// message — or an `error` event. Throws [ChatException] on a non-2xx status
  /// so the caller can fall back to the buffered [sendMessage].
  Stream<ChatStreamEvent> streamMessage({
    required String content,
    int? sessionId,
  }) async* {
    final token = _token();
    final response = await _apiClient.openStream(
      method: 'POST',
      path: '/api/v1/chat/messages/stream',
      payload: <String, Object?>{
        if (sessionId != null) 'session_id': sessionId,
        'content': content,
      },
      token: token,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatException('Akış başlatılamadı (HTTP ${response.statusCode}).');
    }

    String? event;
    final dataBuf = StringBuffer();
    await for (final line
        in response.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        final raw = dataBuf.toString();
        if (event != null || raw.isNotEmpty) {
          Map<String, dynamic>? data;
          if (raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map) {
                data = decoded.map((k, v) => MapEntry(k.toString(), v));
              }
            } on FormatException {
              data = null;
            }
          }
          yield ChatStreamEvent(event ?? 'message', data);
        }
        event = null;
        dataBuf.clear();
        continue;
      }
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        final part = line.substring(5);
        dataBuf.write(part.startsWith(' ') ? part.substring(1) : part);
      }
    }
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
