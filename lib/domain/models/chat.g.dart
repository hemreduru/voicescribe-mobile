// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatSource _$ChatSourceFromJson(Map<String, dynamic> json) => _ChatSource(
  transcriptId: (json['transcript_id'] as num?)?.toInt(),
  title: json['title'] as String? ?? '',
  date: json['date'] as String?,
);

Map<String, dynamic> _$ChatSourceToJson(_ChatSource instance) =>
    <String, dynamic>{
      'transcript_id': instance.transcriptId,
      'title': instance.title,
      'date': instance.date,
    };

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: (json['id'] as num).toInt(),
  role: json['role'] as String,
  content: json['content'] as String? ?? '',
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatSource>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'sources': instance.sources,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => _ChatSession(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String? ?? '',
  lastMessageAt: json['last_message_at'] == null
      ? null
      : DateTime.parse(json['last_message_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  messageCount: (json['message_count'] as num?)?.toInt(),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatMessage>[],
);

Map<String, dynamic> _$ChatSessionToJson(_ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'message_count': instance.messageCount,
      'messages': instance.messages,
    };
