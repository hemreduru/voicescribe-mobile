import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';
part 'chat.g.dart';

/// A transcript the assistant drew an answer from (source attribution).
@freezed
abstract class ChatSource with _$ChatSource {
  const factory ChatSource({
    @JsonKey(name: 'transcript_id') int? transcriptId,
    @Default('') String title,
    String? date,
  }) = _ChatSource;

  factory ChatSource.fromJson(Map<String, dynamic> json) =>
      _$ChatSourceFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    required String role, // 'user' | 'assistant'
    @Default('') String content,
    @Default(<ChatSource>[]) List<ChatSource> sources,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ChatMessage;

  const ChatMessage._();

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

@freezed
abstract class ChatSession with _$ChatSession {
  const factory ChatSession({
    required int id,
    @Default('') String title,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'message_count') int? messageCount,
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
}
