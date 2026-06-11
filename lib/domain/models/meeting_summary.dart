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
          .map(_stringifyItem)
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Renders a list item as readable text. Small models sometimes emit objects
  /// (e.g. `{owner, task, due_date}`) inside string arrays; surface a meaningful
  /// field instead of dumping a raw `{...}` map to the user.
  static String? _stringifyItem(Object? item) {
    if (item == null) return null;
    if (item is String) {
      final t = item.trim();
      return t.isEmpty ? null : t;
    }
    if (item is num || item is bool) return item.toString();
    if (item is Map) {
      for (final key in const [
        'task',
        'text',
        'title',
        'decision',
        'description',
        'name',
        'question',
        'item',
        'value',
      ]) {
        final value = item[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      final parts = item.values
          .where((v) => v != null && v is! Map && v is! List)
          .map((v) => v.toString().trim())
          .where((v) => v.isNotEmpty);
      final joined = parts.join(' — ');
      return joined.isEmpty ? null : joined;
    }
    if (item is List) {
      final joined = item.map(_stringifyItem).whereType<String>().join(', ');
      return joined.isEmpty ? null : joined;
    }
    final s = item.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  Object? toJson(List<String> object) => object;
}

/// Trims [value] to a non-empty string, stringifying numbers/bools; returns null
/// for null, empty, or container values (used to coerce scalar object fields a
/// weak model may emit with the wrong type, e.g. `"due_date": 5`).
String? _coerceScalarString(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  if (value is num || value is bool) return value.toString();
  return null;
}

/// Returns the first non-empty scalar string found among [keys] in [map].
String? _firstScalarString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = _coerceScalarString(map[key]);
    if (value != null) return value;
  }
  return null;
}

/// Coerces a value into `List<ActionItem>`, tolerating a weak local model that
/// emits a bare string, a single object, or a string array where the schema
/// expects an array of `{owner, task, due_date}` objects. Field values are
/// coerced to strings so a numeric `due_date` (etc.) never blows up parsing.
class _FlexibleActionItemList
    implements JsonConverter<List<ActionItem>, Object?> {
  const _FlexibleActionItemList();

  @override
  List<ActionItem> fromJson(Object? json) {
    if (json == null) return const [];
    if (json is String) {
      final t = json.trim();
      return t.isEmpty ? const [] : [ActionItem(task: t)];
    }
    if (json is Map) {
      final item = _fromMap(json);
      return item == null ? const [] : [item];
    }
    if (json is List) {
      final out = <ActionItem>[];
      for (final entry in json) {
        if (entry is String) {
          final t = entry.trim();
          if (t.isNotEmpty) out.add(ActionItem(task: t));
        } else if (entry is Map) {
          final item = _fromMap(entry);
          if (item != null) out.add(item);
        }
      }
      return out;
    }
    return const [];
  }

  static ActionItem? _fromMap(Map<dynamic, dynamic> raw) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final task = _firstScalarString(map, const [
      'task',
      'text',
      'action',
      'description',
      'item',
      'title',
    ]);
    final owner = _firstScalarString(map, const [
      'owner',
      'assignee',
      'responsible',
      'person',
      'name',
    ]);
    final due = _firstScalarString(map, const [
      'due_date',
      'due',
      'deadline',
      'date',
    ]);
    if (task == null && owner == null && due == null) return null;
    return ActionItem(owner: owner, task: task ?? '', dueDate: due);
  }

  @override
  Object toJson(List<ActionItem> object) =>
      object.map((item) => item.toJson()).toList();
}

/// Coerces a value into `List<AgendaItem>` with the same tolerance as
/// [_FlexibleActionItemList]: bare string, single object, or string array all
/// become a clean list of `{title, discussion, conclusion}` items.
class _FlexibleAgendaItemList
    implements JsonConverter<List<AgendaItem>, Object?> {
  const _FlexibleAgendaItemList();

  @override
  List<AgendaItem> fromJson(Object? json) {
    if (json == null) return const [];
    if (json is String) {
      final t = json.trim();
      return t.isEmpty ? const [] : [AgendaItem(title: t)];
    }
    if (json is Map) {
      final item = _fromMap(json);
      return item == null ? const [] : [item];
    }
    if (json is List) {
      final out = <AgendaItem>[];
      for (final entry in json) {
        if (entry is String) {
          final t = entry.trim();
          if (t.isNotEmpty) out.add(AgendaItem(title: t));
        } else if (entry is Map) {
          final item = _fromMap(entry);
          if (item != null) out.add(item);
        }
      }
      return out;
    }
    return const [];
  }

  static AgendaItem? _fromMap(Map<dynamic, dynamic> raw) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final title = _firstScalarString(map, const [
      'title',
      'topic',
      'heading',
      'name',
      'item',
    ]);
    final discussion = _firstScalarString(map, const [
      'discussion',
      'details',
      'description',
      'notes',
      'summary',
    ]);
    final conclusion = _firstScalarString(map, const [
      'conclusion',
      'outcome',
      'decision',
      'result',
    ]);
    if (title == null && discussion == null && conclusion == null) {
      return null;
    }
    return AgendaItem(
      title: title ?? '',
      discussion: discussion ?? '',
      conclusion: conclusion,
    );
  }

  @override
  Object toJson(List<AgendaItem> object) =>
      object.map((item) => item.toJson()).toList();
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
    @_FlexibleAgendaItemList()
    @Default(<AgendaItem>[])
    List<AgendaItem> agendaItems,
    @_FlexibleStringList() @Default(<String>[]) List<String> decisions,
    @JsonKey(name: 'action_items')
    @_FlexibleActionItemList()
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
    final stripped = _stripThinkTags(raw);
    // Candidate JSON strings to try in order. The happy path (a clean, balanced
    // object) is tried first and never touched by the repair/normalize layers;
    // those only kick in as fallbacks so valid output is parsed verbatim.
    final candidates = <String>[];
    void addCandidate(String? text) {
      if (text != null && text.isNotEmpty && !candidates.contains(text)) {
        candidates.add(text);
      }
    }

    // 1. Balanced object as-is; 2. truncation repair (model hit the token cap
    // mid-JSON, leaving an unclosed string/array/object).
    addCandidate(_extractJsonObject(stripped));
    addCandidate(_repairTruncatedJsonObject(stripped));
    // 3 & 4. Same two passes over deterministically-normalized text (fixes
    // trailing commas, smart quotes, single-quoted strings, unquoted keys,
    // NaN/Infinity, BOM/control chars) — only reached if the strict passes fail.
    final normalized = _normalizeJsonText(stripped);
    if (normalized != stripped) {
      addCandidate(_extractJsonObject(normalized));
      addCandidate(_repairTruncatedJsonObject(normalized));
    }

    for (final jsonText in candidates) {
      try {
        final decoded = jsonDecode(jsonText);
        final map = _asObjectMap(decoded);
        if (map == null) {
          continue;
        }
        final summary = MeetingSummary.fromJson(map);
        // Guard against valid-but-empty JSON masquerading as a real summary.
        final hasContent =
            summary.title.trim().isNotEmpty ||
            summary.executiveSummary.isNotEmpty ||
            summary.agendaItems.isNotEmpty ||
            summary.decisions.isNotEmpty ||
            summary.actionItems.isNotEmpty;
        if (hasContent) {
          return summary;
        }
      } catch (_) {
        // try the next candidate
      }
    }
    return null;
  }

  /// Coerces a decoded JSON value into a `Map<String, dynamic>` for parsing.
  /// Tolerates the root being an array (uses the first map element) — a weak
  /// model sometimes wraps the object in `[ ... ]`.
  static Map<String, dynamic>? _asObjectMap(Object? decoded) {
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    if (decoded is List) {
      for (final element in decoded) {
        if (element is Map) {
          return element.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    }
    return null;
  }

  /// Deterministically repairs common "almost-JSON" defects a small model emits,
  /// without touching well-formed JSON's meaning. Used only as a fallback (see
  /// [tryParse]) so a clean object is never altered.
  static String _normalizeJsonText(String input) {
    var text = input
        // BOM and zero-width characters.
        .replaceAll('﻿', '')
        .replaceAll('​', '')
        // Smart double quotes (and guillemets) → straight double quote.
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('„', '"')
        .replaceAll('«', '"')
        .replaceAll('»', '"')
        // Smart single quotes → straight single quote.
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('‚', "'");
    // Drop stray control characters (keep tab/newline/carriage return).
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    // Convert single-quoted strings to double-quoted (string-aware scan).
    text = _convertSingleQuotedStrings(text);
    // Quote bare identifier keys: `{ key: ...` → `{ "key": ...`.
    text = text.replaceAllMapped(
      RegExp(r'([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*:)'),
      (m) => '${m[1]}"${m[2]}"${m[3]}',
    );
    // NaN / Infinity literals in a value position → null.
    text = text.replaceAllMapped(
      RegExp(r'([:,\[]\s*)(-?Infinity|NaN)\b'),
      (m) => '${m[1]}null',
    );
    // Trailing commas before a closing brace/bracket.
    text = text.replaceAllMapped(RegExp(r',(\s*[}\]])'), (m) => m[1]!);
    return text;
  }

  /// Rewrites single-quoted JSON strings as double-quoted ones, leaving
  /// already double-quoted strings untouched. Escapes inner double quotes and
  /// unescapes `\'`.
  static String _convertSingleQuotedStrings(String s) {
    final out = StringBuffer();
    final n = s.length;
    var i = 0;
    while (i < n) {
      final c = s[i];
      if (c == '"') {
        // Copy a double-quoted string verbatim (respecting escapes).
        out.write(c);
        i++;
        while (i < n) {
          final d = s[i];
          out.write(d);
          i++;
          if (d == r'\' && i < n) {
            out.write(s[i]);
            i++;
            continue;
          }
          if (d == '"') break;
        }
        continue;
      }
      if (c == "'") {
        out.write('"');
        i++;
        while (i < n) {
          final d = s[i];
          if (d == r'\' && i + 1 < n) {
            final e = s[i + 1];
            if (e == "'") {
              out.write("'");
            } else {
              out
                ..write(d)
                ..write(e);
            }
            i += 2;
            continue;
          }
          if (d == '"') {
            out.write(r'\"');
            i++;
            continue;
          }
          if (d == "'") {
            i++;
            break;
          }
          out.write(d);
          i++;
        }
        out.write('"');
        continue;
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }

  /// Repairs a truncated JSON object (model hit its token cap mid-output) by
  /// closing an unclosed string and any open arrays/objects, dropping a dangling
  /// trailing comma or `"key":` with no value. Returns null if there is no `{`.
  static String? _repairTruncatedJsonObject(String input) {
    final text = _stripCodeFences(_stripThinkTags(input).trim());
    final start = text.indexOf('{');
    if (start < 0) {
      return null;
    }
    const quote = 0x22;
    const backslash = 0x5c;
    const openBrace = 0x7b;
    const closeBrace = 0x7d;
    const openBracket = 0x5b;
    const closeBracket = 0x5d;
    final stack = <int>[];
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
      } else if (ch == openBrace || ch == openBracket) {
        stack.add(ch);
      } else if (ch == closeBrace || ch == closeBracket) {
        if (stack.isNotEmpty) stack.removeLast();
      }
    }

    final buffer = StringBuffer(text.substring(start));
    if (inString) {
      buffer.write('"');
    }
    // Drop a dangling separator / empty key-value tail.
    var tail = buffer.toString().replaceFirst(RegExp(r'[\s,]+$'), '');
    if (tail.endsWith(':')) {
      tail += 'null';
    }
    final out = StringBuffer(tail);
    for (var i = stack.length - 1; i >= 0; i--) {
      out.write(stack[i] == openBracket ? ']' : '}');
    }
    return out.toString();
  }

  /// Returns true when [raw] looks like it was meant to be JSON (so the UI should
  /// treat a parse failure as a generation error, not render it as plain text).
  ///
  /// Checks for a JSON object anywhere in the text, not just at the start: a
  /// weak model can prepend prose ("İşte özet:\n{...}") before emitting the
  /// object, and we must never let those raw braces fall through to the
  /// plain-text render path.
  static bool looksLikeJson(String raw) {
    final t = _stripThinkTags(raw).trimLeft();
    if (t.startsWith('{') || t.startsWith('```')) {
      return true;
    }
    // A `{` followed (whitespace-tolerant) by a quoted key is unmistakably an
    // attempted JSON object — genuine meeting prose does not contain `{"`.
    return RegExp(r'\{\s*"').hasMatch(t);
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
