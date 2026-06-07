// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeetingSummary _$MeetingSummaryFromJson(Map<String, dynamic> json) =>
    _MeetingSummary(
      schemaVersion:
          (json['schema_version'] as num?)?.toInt() ??
          kMeetingSummarySchemaVersion,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      metadata: json['metadata'] == null
          ? const MeetingMetadata()
          : MeetingMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      executiveSummary: json['executive_summary'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['executive_summary']),
      agendaItems:
          (json['agenda_items'] as List<dynamic>?)
              ?.map((e) => AgendaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AgendaItem>[],
      decisions: json['decisions'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['decisions']),
      actionItems:
          (json['action_items'] as List<dynamic>?)
              ?.map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ActionItem>[],
      openQuestions: json['open_questions'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['open_questions']),
      nextMeeting: json['next_meeting'] as String?,
      notes: json['notes'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['notes']),
    );

Map<String, dynamic> _$MeetingSummaryToJson(
  _MeetingSummary instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'metadata': instance.metadata,
  'executive_summary': const _FlexibleStringList().toJson(
    instance.executiveSummary,
  ),
  'agenda_items': instance.agendaItems,
  'decisions': const _FlexibleStringList().toJson(instance.decisions),
  'action_items': instance.actionItems,
  'open_questions': const _FlexibleStringList().toJson(instance.openQuestions),
  'next_meeting': instance.nextMeeting,
  'notes': const _FlexibleStringList().toJson(instance.notes),
};

_MeetingMetadata _$MeetingMetadataFromJson(Map<String, dynamic> json) =>
    _MeetingMetadata(
      topic: json['topic'] as String?,
      date: json['date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      location: json['location'] as String?,
      attendees: json['attendees'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['attendees']),
      absentees: json['absentees'] == null
          ? const <String>[]
          : const _FlexibleStringList().fromJson(json['absentees']),
      recorder: json['recorder'] as String?,
    );

Map<String, dynamic> _$MeetingMetadataToJson(_MeetingMetadata instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'date': instance.date,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'location': instance.location,
      'attendees': const _FlexibleStringList().toJson(instance.attendees),
      'absentees': const _FlexibleStringList().toJson(instance.absentees),
      'recorder': instance.recorder,
    };

_AgendaItem _$AgendaItemFromJson(Map<String, dynamic> json) => _AgendaItem(
  title: json['title'] as String? ?? '',
  discussion: json['discussion'] as String? ?? '',
  conclusion: json['conclusion'] as String?,
);

Map<String, dynamic> _$AgendaItemToJson(_AgendaItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'discussion': instance.discussion,
      'conclusion': instance.conclusion,
    };

_ActionItem _$ActionItemFromJson(Map<String, dynamic> json) => _ActionItem(
  owner: json['owner'] as String?,
  task: json['task'] as String? ?? '',
  dueDate: json['due_date'] as String?,
);

Map<String, dynamic> _$ActionItemToJson(_ActionItem instance) =>
    <String, dynamic>{
      'owner': instance.owner,
      'task': instance.task,
      'due_date': instance.dueDate,
    };
