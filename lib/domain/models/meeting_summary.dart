import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_summary.freezed.dart';
part 'meeting_summary.g.dart';

/// Schema version of the structured meeting-minutes contract. Both the backend
/// (MeetingMinutesPrompt::SCHEMA_VERSION) and the on-device prompt emit this.
const int kMeetingSummarySchemaVersion = 1;

/// Coerces a value into a `List<String>`, tolerating a weak local model that
/// returns a bare string (or null) where the schema expects an array.
class _FlexibleStringList implements JsonConverter<List<String>, Object?> {
  const _FlexibleStringList();

  @override
  List<String> fromJson(Object? json) {
    if (json is String) {
      final trimmed = json.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    if (json is List) {
      return json
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Object? toJson(List<String> object) => object;
}

/// Structured meeting-minutes summary parsed from `Summary.summaryText`.
///
/// The JSON contract is shared with the backend; see
/// app/Services/Summarization/MeetingMinutesPrompt.php.
@freezed
abstract class MeetingSummary with _$MeetingSummary {
  const factory MeetingSummary({
    @JsonKey(name: 'schema_version')
    @Default(kMeetingSummarySchemaVersion)
    int schemaVersion,
    @Default('') String title,
    String? subtitle,
    @Default(MeetingMetadata()) MeetingMetadata metadata,
    @JsonKey(name: 'executive_summary')
    @_FlexibleStringList()
    @Default(<String>[])
    List<String> executiveSummary,
    @JsonKey(name: 'agenda_items')
    @Default(<AgendaItem>[])
    List<AgendaItem> agendaItems,
    @_FlexibleStringList() @Default(<String>[]) List<String> decisions,
    @JsonKey(name: 'action_items')
    @Default(<ActionItem>[])
    List<ActionItem> actionItems,
    @JsonKey(name: 'open_questions')
    @_FlexibleStringList()
    @Default(<String>[])
    List<String> openQuestions,
    @JsonKey(name: 'next_meeting') String? nextMeeting,
    @_FlexibleStringList() @Default(<String>[]) List<String> notes,
  }) = _MeetingSummary;

  const MeetingSummary._();

  factory MeetingSummary.fromJson(Map<String, dynamic> json) =>
      _$MeetingSummaryFromJson(json);

  /// Tolerantly parses a raw summary string into a [MeetingSummary].
  ///
  /// Extracts the first balanced JSON object (tolerating thinking tags, code
  /// fences, and leading/trailing model noise like repetition loops). Returns
  /// `null` for legacy plain-text summaries or unrecoverable output.
  static MeetingSummary? tryParse(String raw) {
    final jsonText = _extractJsonObject(_stripThinkTags(raw));
    if (jsonText == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return null;
      }
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      final summary = MeetingSummary.fromJson(map);
      // Guard against valid-but-empty JSON masquerading as a real summary.
      final hasContent =
          summary.title.trim().isNotEmpty ||
          summary.executiveSummary.isNotEmpty ||
          summary.agendaItems.isNotEmpty ||
          summary.decisions.isNotEmpty ||
          summary.actionItems.isNotEmpty;
      return hasContent ? summary : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when [raw] looks like it was meant to be JSON (so the UI should
  /// treat a parse failure as a generation error, not render it as plain text).
  static bool looksLikeJson(String raw) {
    final t = _stripThinkTags(raw).trimLeft();
    return t.startsWith('{') || t.startsWith('```');
  }

  static String _stripThinkTags(String input) {
    // Qwen3 and other hybrid models may wrap reasoning in <think>...</think>.
    return input.replaceAll(
      RegExp('<think>.*?</think>', dotAll: true, caseSensitive: false),
      '',
    );
  }

  /// Extracts the first balanced `{...}` object from [input], ignoring braces
  /// inside strings. Tolerates leading/trailing noise and code fences.
  static String? _extractJsonObject(String input) {
    final text = _stripCodeFences(input.trim());
    final start = text.indexOf('{');
    if (start < 0) {
      return null;
    }
    const quote = 0x22; // "
    const backslash = 0x5c; // \
    const openBrace = 0x7b; // {
    const closeBrace = 0x7d; // }
    var depth = 0;
    var inString = false;
    var escaped = false;
    final units = text.codeUnits;
    for (var i = start; i < units.length; i++) {
      final ch = units[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == backslash) {
          escaped = true;
        } else if (ch == quote) {
          inString = false;
        }
        continue;
      }
      if (ch == quote) {
        inString = true;
      } else if (ch == openBrace) {
        depth++;
      } else if (ch == closeBrace) {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  /// Serializes back to the canonical JSON string for storage.
  String toJsonString() => jsonEncode(toJson());

  bool get hasMetadataDetails =>
      (metadata.date ?? '').isNotEmpty ||
      (metadata.startTime ?? '').isNotEmpty ||
      (metadata.endTime ?? '').isNotEmpty ||
      (metadata.location ?? '').isNotEmpty ||
      (metadata.recorder ?? '').isNotEmpty ||
      metadata.attendees.isNotEmpty ||
      metadata.absentees.isNotEmpty;

  /// Strips ```json ... ``` fences a model may wrap its output in.
  static String _stripCodeFences(String input) {
    if (!input.startsWith('```')) {
      return input;
    }
    var text = input.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}

@freezed
abstract class MeetingMetadata with _$MeetingMetadata {
  const factory MeetingMetadata({
    String? topic,
    String? date,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    String? location,
    @_FlexibleStringList() @Default(<String>[]) List<String> attendees,
    @_FlexibleStringList() @Default(<String>[]) List<String> absentees,
    String? recorder,
  }) = _MeetingMetadata;

  factory MeetingMetadata.fromJson(Map<String, dynamic> json) =>
      _$MeetingMetadataFromJson(json);
}

@freezed
abstract class AgendaItem with _$AgendaItem {
  const factory AgendaItem({
    @Default('') String title,
    @Default('') String discussion,
    String? conclusion,
  }) = _AgendaItem;

  factory AgendaItem.fromJson(Map<String, dynamic> json) =>
      _$AgendaItemFromJson(json);
}

@freezed
abstract class ActionItem with _$ActionItem {
  const factory ActionItem({
    String? owner,
    @Default('') String task,
    @JsonKey(name: 'due_date') String? dueDate,
  }) = _ActionItem;

  factory ActionItem.fromJson(Map<String, dynamic> json) =>
      _$ActionItemFromJson(json);
}
