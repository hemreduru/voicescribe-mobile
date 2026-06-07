// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeetingSummary {

@JsonKey(name: 'schema_version') int get schemaVersion; String get title; String? get subtitle; MeetingMetadata get metadata;@JsonKey(name: 'executive_summary')@_FlexibleStringList() List<String> get executiveSummary;@JsonKey(name: 'agenda_items') List<AgendaItem> get agendaItems;@_FlexibleStringList() List<String> get decisions;@JsonKey(name: 'action_items') List<ActionItem> get actionItems;@JsonKey(name: 'open_questions')@_FlexibleStringList() List<String> get openQuestions;@JsonKey(name: 'next_meeting') String? get nextMeeting;@_FlexibleStringList() List<String> get notes;
/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeetingSummaryCopyWith<MeetingSummary> get copyWith => _$MeetingSummaryCopyWithImpl<MeetingSummary>(this as MeetingSummary, _$identity);

  /// Serializes this MeetingSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeetingSummary&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.executiveSummary, executiveSummary)&&const DeepCollectionEquality().equals(other.agendaItems, agendaItems)&&const DeepCollectionEquality().equals(other.decisions, decisions)&&const DeepCollectionEquality().equals(other.actionItems, actionItems)&&const DeepCollectionEquality().equals(other.openQuestions, openQuestions)&&(identical(other.nextMeeting, nextMeeting) || other.nextMeeting == nextMeeting)&&const DeepCollectionEquality().equals(other.notes, notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,title,subtitle,metadata,const DeepCollectionEquality().hash(executiveSummary),const DeepCollectionEquality().hash(agendaItems),const DeepCollectionEquality().hash(decisions),const DeepCollectionEquality().hash(actionItems),const DeepCollectionEquality().hash(openQuestions),nextMeeting,const DeepCollectionEquality().hash(notes));

@override
String toString() {
  return 'MeetingSummary(schemaVersion: $schemaVersion, title: $title, subtitle: $subtitle, metadata: $metadata, executiveSummary: $executiveSummary, agendaItems: $agendaItems, decisions: $decisions, actionItems: $actionItems, openQuestions: $openQuestions, nextMeeting: $nextMeeting, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MeetingSummaryCopyWith<$Res>  {
  factory $MeetingSummaryCopyWith(MeetingSummary value, $Res Function(MeetingSummary) _then) = _$MeetingSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'schema_version') int schemaVersion, String title, String? subtitle, MeetingMetadata metadata,@JsonKey(name: 'executive_summary')@_FlexibleStringList() List<String> executiveSummary,@JsonKey(name: 'agenda_items') List<AgendaItem> agendaItems,@_FlexibleStringList() List<String> decisions,@JsonKey(name: 'action_items') List<ActionItem> actionItems,@JsonKey(name: 'open_questions')@_FlexibleStringList() List<String> openQuestions,@JsonKey(name: 'next_meeting') String? nextMeeting,@_FlexibleStringList() List<String> notes
});


$MeetingMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$MeetingSummaryCopyWithImpl<$Res>
    implements $MeetingSummaryCopyWith<$Res> {
  _$MeetingSummaryCopyWithImpl(this._self, this._then);

  final MeetingSummary _self;
  final $Res Function(MeetingSummary) _then;

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? title = null,Object? subtitle = freezed,Object? metadata = null,Object? executiveSummary = null,Object? agendaItems = null,Object? decisions = null,Object? actionItems = null,Object? openQuestions = null,Object? nextMeeting = freezed,Object? notes = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MeetingMetadata,executiveSummary: null == executiveSummary ? _self.executiveSummary : executiveSummary // ignore: cast_nullable_to_non_nullable
as List<String>,agendaItems: null == agendaItems ? _self.agendaItems : agendaItems // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,decisions: null == decisions ? _self.decisions : decisions // ignore: cast_nullable_to_non_nullable
as List<String>,actionItems: null == actionItems ? _self.actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<ActionItem>,openQuestions: null == openQuestions ? _self.openQuestions : openQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,nextMeeting: freezed == nextMeeting ? _self.nextMeeting : nextMeeting // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeetingMetadataCopyWith<$Res> get metadata {
  
  return $MeetingMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [MeetingSummary].
extension MeetingSummaryPatterns on MeetingSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeetingSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeetingSummary value)  $default,){
final _that = this;
switch (_that) {
case _MeetingSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeetingSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'schema_version')  int schemaVersion,  String title,  String? subtitle,  MeetingMetadata metadata, @JsonKey(name: 'executive_summary')@_FlexibleStringList()  List<String> executiveSummary, @JsonKey(name: 'agenda_items')  List<AgendaItem> agendaItems, @_FlexibleStringList()  List<String> decisions, @JsonKey(name: 'action_items')  List<ActionItem> actionItems, @JsonKey(name: 'open_questions')@_FlexibleStringList()  List<String> openQuestions, @JsonKey(name: 'next_meeting')  String? nextMeeting, @_FlexibleStringList()  List<String> notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that.schemaVersion,_that.title,_that.subtitle,_that.metadata,_that.executiveSummary,_that.agendaItems,_that.decisions,_that.actionItems,_that.openQuestions,_that.nextMeeting,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'schema_version')  int schemaVersion,  String title,  String? subtitle,  MeetingMetadata metadata, @JsonKey(name: 'executive_summary')@_FlexibleStringList()  List<String> executiveSummary, @JsonKey(name: 'agenda_items')  List<AgendaItem> agendaItems, @_FlexibleStringList()  List<String> decisions, @JsonKey(name: 'action_items')  List<ActionItem> actionItems, @JsonKey(name: 'open_questions')@_FlexibleStringList()  List<String> openQuestions, @JsonKey(name: 'next_meeting')  String? nextMeeting, @_FlexibleStringList()  List<String> notes)  $default,) {final _that = this;
switch (_that) {
case _MeetingSummary():
return $default(_that.schemaVersion,_that.title,_that.subtitle,_that.metadata,_that.executiveSummary,_that.agendaItems,_that.decisions,_that.actionItems,_that.openQuestions,_that.nextMeeting,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'schema_version')  int schemaVersion,  String title,  String? subtitle,  MeetingMetadata metadata, @JsonKey(name: 'executive_summary')@_FlexibleStringList()  List<String> executiveSummary, @JsonKey(name: 'agenda_items')  List<AgendaItem> agendaItems, @_FlexibleStringList()  List<String> decisions, @JsonKey(name: 'action_items')  List<ActionItem> actionItems, @JsonKey(name: 'open_questions')@_FlexibleStringList()  List<String> openQuestions, @JsonKey(name: 'next_meeting')  String? nextMeeting, @_FlexibleStringList()  List<String> notes)?  $default,) {final _that = this;
switch (_that) {
case _MeetingSummary() when $default != null:
return $default(_that.schemaVersion,_that.title,_that.subtitle,_that.metadata,_that.executiveSummary,_that.agendaItems,_that.decisions,_that.actionItems,_that.openQuestions,_that.nextMeeting,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeetingSummary extends MeetingSummary {
  const _MeetingSummary({@JsonKey(name: 'schema_version') this.schemaVersion = kMeetingSummarySchemaVersion, this.title = '', this.subtitle, this.metadata = const MeetingMetadata(), @JsonKey(name: 'executive_summary')@_FlexibleStringList() final  List<String> executiveSummary = const <String>[], @JsonKey(name: 'agenda_items') final  List<AgendaItem> agendaItems = const <AgendaItem>[], @_FlexibleStringList() final  List<String> decisions = const <String>[], @JsonKey(name: 'action_items') final  List<ActionItem> actionItems = const <ActionItem>[], @JsonKey(name: 'open_questions')@_FlexibleStringList() final  List<String> openQuestions = const <String>[], @JsonKey(name: 'next_meeting') this.nextMeeting, @_FlexibleStringList() final  List<String> notes = const <String>[]}): _executiveSummary = executiveSummary,_agendaItems = agendaItems,_decisions = decisions,_actionItems = actionItems,_openQuestions = openQuestions,_notes = notes,super._();
  factory _MeetingSummary.fromJson(Map<String, dynamic> json) => _$MeetingSummaryFromJson(json);

@override@JsonKey(name: 'schema_version') final  int schemaVersion;
@override@JsonKey() final  String title;
@override final  String? subtitle;
@override@JsonKey() final  MeetingMetadata metadata;
 final  List<String> _executiveSummary;
@override@JsonKey(name: 'executive_summary')@_FlexibleStringList() List<String> get executiveSummary {
  if (_executiveSummary is EqualUnmodifiableListView) return _executiveSummary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_executiveSummary);
}

 final  List<AgendaItem> _agendaItems;
@override@JsonKey(name: 'agenda_items') List<AgendaItem> get agendaItems {
  if (_agendaItems is EqualUnmodifiableListView) return _agendaItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agendaItems);
}

 final  List<String> _decisions;
@override@JsonKey()@_FlexibleStringList() List<String> get decisions {
  if (_decisions is EqualUnmodifiableListView) return _decisions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_decisions);
}

 final  List<ActionItem> _actionItems;
@override@JsonKey(name: 'action_items') List<ActionItem> get actionItems {
  if (_actionItems is EqualUnmodifiableListView) return _actionItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actionItems);
}

 final  List<String> _openQuestions;
@override@JsonKey(name: 'open_questions')@_FlexibleStringList() List<String> get openQuestions {
  if (_openQuestions is EqualUnmodifiableListView) return _openQuestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openQuestions);
}

@override@JsonKey(name: 'next_meeting') final  String? nextMeeting;
 final  List<String> _notes;
@override@JsonKey()@_FlexibleStringList() List<String> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}


/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeetingSummaryCopyWith<_MeetingSummary> get copyWith => __$MeetingSummaryCopyWithImpl<_MeetingSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeetingSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeetingSummary&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._executiveSummary, _executiveSummary)&&const DeepCollectionEquality().equals(other._agendaItems, _agendaItems)&&const DeepCollectionEquality().equals(other._decisions, _decisions)&&const DeepCollectionEquality().equals(other._actionItems, _actionItems)&&const DeepCollectionEquality().equals(other._openQuestions, _openQuestions)&&(identical(other.nextMeeting, nextMeeting) || other.nextMeeting == nextMeeting)&&const DeepCollectionEquality().equals(other._notes, _notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,title,subtitle,metadata,const DeepCollectionEquality().hash(_executiveSummary),const DeepCollectionEquality().hash(_agendaItems),const DeepCollectionEquality().hash(_decisions),const DeepCollectionEquality().hash(_actionItems),const DeepCollectionEquality().hash(_openQuestions),nextMeeting,const DeepCollectionEquality().hash(_notes));

@override
String toString() {
  return 'MeetingSummary(schemaVersion: $schemaVersion, title: $title, subtitle: $subtitle, metadata: $metadata, executiveSummary: $executiveSummary, agendaItems: $agendaItems, decisions: $decisions, actionItems: $actionItems, openQuestions: $openQuestions, nextMeeting: $nextMeeting, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$MeetingSummaryCopyWith<$Res> implements $MeetingSummaryCopyWith<$Res> {
  factory _$MeetingSummaryCopyWith(_MeetingSummary value, $Res Function(_MeetingSummary) _then) = __$MeetingSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'schema_version') int schemaVersion, String title, String? subtitle, MeetingMetadata metadata,@JsonKey(name: 'executive_summary')@_FlexibleStringList() List<String> executiveSummary,@JsonKey(name: 'agenda_items') List<AgendaItem> agendaItems,@_FlexibleStringList() List<String> decisions,@JsonKey(name: 'action_items') List<ActionItem> actionItems,@JsonKey(name: 'open_questions')@_FlexibleStringList() List<String> openQuestions,@JsonKey(name: 'next_meeting') String? nextMeeting,@_FlexibleStringList() List<String> notes
});


@override $MeetingMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$MeetingSummaryCopyWithImpl<$Res>
    implements _$MeetingSummaryCopyWith<$Res> {
  __$MeetingSummaryCopyWithImpl(this._self, this._then);

  final _MeetingSummary _self;
  final $Res Function(_MeetingSummary) _then;

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? title = null,Object? subtitle = freezed,Object? metadata = null,Object? executiveSummary = null,Object? agendaItems = null,Object? decisions = null,Object? actionItems = null,Object? openQuestions = null,Object? nextMeeting = freezed,Object? notes = null,}) {
  return _then(_MeetingSummary(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as MeetingMetadata,executiveSummary: null == executiveSummary ? _self._executiveSummary : executiveSummary // ignore: cast_nullable_to_non_nullable
as List<String>,agendaItems: null == agendaItems ? _self._agendaItems : agendaItems // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,decisions: null == decisions ? _self._decisions : decisions // ignore: cast_nullable_to_non_nullable
as List<String>,actionItems: null == actionItems ? _self._actionItems : actionItems // ignore: cast_nullable_to_non_nullable
as List<ActionItem>,openQuestions: null == openQuestions ? _self._openQuestions : openQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,nextMeeting: freezed == nextMeeting ? _self.nextMeeting : nextMeeting // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of MeetingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeetingMetadataCopyWith<$Res> get metadata {
  
  return $MeetingMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$MeetingMetadata {

 String? get topic; String? get date;@JsonKey(name: 'start_time') String? get startTime;@JsonKey(name: 'end_time') String? get endTime; String? get location;@_FlexibleStringList() List<String> get attendees;@_FlexibleStringList() List<String> get absentees; String? get recorder;
/// Create a copy of MeetingMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeetingMetadataCopyWith<MeetingMetadata> get copyWith => _$MeetingMetadataCopyWithImpl<MeetingMetadata>(this as MeetingMetadata, _$identity);

  /// Serializes this MeetingMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeetingMetadata&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.attendees, attendees)&&const DeepCollectionEquality().equals(other.absentees, absentees)&&(identical(other.recorder, recorder) || other.recorder == recorder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,date,startTime,endTime,location,const DeepCollectionEquality().hash(attendees),const DeepCollectionEquality().hash(absentees),recorder);

@override
String toString() {
  return 'MeetingMetadata(topic: $topic, date: $date, startTime: $startTime, endTime: $endTime, location: $location, attendees: $attendees, absentees: $absentees, recorder: $recorder)';
}


}

/// @nodoc
abstract mixin class $MeetingMetadataCopyWith<$Res>  {
  factory $MeetingMetadataCopyWith(MeetingMetadata value, $Res Function(MeetingMetadata) _then) = _$MeetingMetadataCopyWithImpl;
@useResult
$Res call({
 String? topic, String? date,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, String? location,@_FlexibleStringList() List<String> attendees,@_FlexibleStringList() List<String> absentees, String? recorder
});




}
/// @nodoc
class _$MeetingMetadataCopyWithImpl<$Res>
    implements $MeetingMetadataCopyWith<$Res> {
  _$MeetingMetadataCopyWithImpl(this._self, this._then);

  final MeetingMetadata _self;
  final $Res Function(MeetingMetadata) _then;

/// Create a copy of MeetingMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = freezed,Object? date = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? location = freezed,Object? attendees = null,Object? absentees = null,Object? recorder = freezed,}) {
  return _then(_self.copyWith(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,attendees: null == attendees ? _self.attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<String>,absentees: null == absentees ? _self.absentees : absentees // ignore: cast_nullable_to_non_nullable
as List<String>,recorder: freezed == recorder ? _self.recorder : recorder // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeetingMetadata].
extension MeetingMetadataPatterns on MeetingMetadata {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeetingMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeetingMetadata() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeetingMetadata value)  $default,){
final _that = this;
switch (_that) {
case _MeetingMetadata():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeetingMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _MeetingMetadata() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? topic,  String? date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @_FlexibleStringList()  List<String> attendees, @_FlexibleStringList()  List<String> absentees,  String? recorder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeetingMetadata() when $default != null:
return $default(_that.topic,_that.date,_that.startTime,_that.endTime,_that.location,_that.attendees,_that.absentees,_that.recorder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? topic,  String? date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @_FlexibleStringList()  List<String> attendees, @_FlexibleStringList()  List<String> absentees,  String? recorder)  $default,) {final _that = this;
switch (_that) {
case _MeetingMetadata():
return $default(_that.topic,_that.date,_that.startTime,_that.endTime,_that.location,_that.attendees,_that.absentees,_that.recorder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? topic,  String? date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @_FlexibleStringList()  List<String> attendees, @_FlexibleStringList()  List<String> absentees,  String? recorder)?  $default,) {final _that = this;
switch (_that) {
case _MeetingMetadata() when $default != null:
return $default(_that.topic,_that.date,_that.startTime,_that.endTime,_that.location,_that.attendees,_that.absentees,_that.recorder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeetingMetadata implements MeetingMetadata {
  const _MeetingMetadata({this.topic, this.date, @JsonKey(name: 'start_time') this.startTime, @JsonKey(name: 'end_time') this.endTime, this.location, @_FlexibleStringList() final  List<String> attendees = const <String>[], @_FlexibleStringList() final  List<String> absentees = const <String>[], this.recorder}): _attendees = attendees,_absentees = absentees;
  factory _MeetingMetadata.fromJson(Map<String, dynamic> json) => _$MeetingMetadataFromJson(json);

@override final  String? topic;
@override final  String? date;
@override@JsonKey(name: 'start_time') final  String? startTime;
@override@JsonKey(name: 'end_time') final  String? endTime;
@override final  String? location;
 final  List<String> _attendees;
@override@JsonKey()@_FlexibleStringList() List<String> get attendees {
  if (_attendees is EqualUnmodifiableListView) return _attendees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attendees);
}

 final  List<String> _absentees;
@override@JsonKey()@_FlexibleStringList() List<String> get absentees {
  if (_absentees is EqualUnmodifiableListView) return _absentees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_absentees);
}

@override final  String? recorder;

/// Create a copy of MeetingMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeetingMetadataCopyWith<_MeetingMetadata> get copyWith => __$MeetingMetadataCopyWithImpl<_MeetingMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeetingMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeetingMetadata&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._attendees, _attendees)&&const DeepCollectionEquality().equals(other._absentees, _absentees)&&(identical(other.recorder, recorder) || other.recorder == recorder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,date,startTime,endTime,location,const DeepCollectionEquality().hash(_attendees),const DeepCollectionEquality().hash(_absentees),recorder);

@override
String toString() {
  return 'MeetingMetadata(topic: $topic, date: $date, startTime: $startTime, endTime: $endTime, location: $location, attendees: $attendees, absentees: $absentees, recorder: $recorder)';
}


}

/// @nodoc
abstract mixin class _$MeetingMetadataCopyWith<$Res> implements $MeetingMetadataCopyWith<$Res> {
  factory _$MeetingMetadataCopyWith(_MeetingMetadata value, $Res Function(_MeetingMetadata) _then) = __$MeetingMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? topic, String? date,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, String? location,@_FlexibleStringList() List<String> attendees,@_FlexibleStringList() List<String> absentees, String? recorder
});




}
/// @nodoc
class __$MeetingMetadataCopyWithImpl<$Res>
    implements _$MeetingMetadataCopyWith<$Res> {
  __$MeetingMetadataCopyWithImpl(this._self, this._then);

  final _MeetingMetadata _self;
  final $Res Function(_MeetingMetadata) _then;

/// Create a copy of MeetingMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = freezed,Object? date = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? location = freezed,Object? attendees = null,Object? absentees = null,Object? recorder = freezed,}) {
  return _then(_MeetingMetadata(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,attendees: null == attendees ? _self._attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<String>,absentees: null == absentees ? _self._absentees : absentees // ignore: cast_nullable_to_non_nullable
as List<String>,recorder: freezed == recorder ? _self.recorder : recorder // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgendaItem {

 String get title; String get discussion; String? get conclusion;
/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgendaItemCopyWith<AgendaItem> get copyWith => _$AgendaItemCopyWithImpl<AgendaItem>(this as AgendaItem, _$identity);

  /// Serializes this AgendaItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgendaItem&&(identical(other.title, title) || other.title == title)&&(identical(other.discussion, discussion) || other.discussion == discussion)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,discussion,conclusion);

@override
String toString() {
  return 'AgendaItem(title: $title, discussion: $discussion, conclusion: $conclusion)';
}


}

/// @nodoc
abstract mixin class $AgendaItemCopyWith<$Res>  {
  factory $AgendaItemCopyWith(AgendaItem value, $Res Function(AgendaItem) _then) = _$AgendaItemCopyWithImpl;
@useResult
$Res call({
 String title, String discussion, String? conclusion
});




}
/// @nodoc
class _$AgendaItemCopyWithImpl<$Res>
    implements $AgendaItemCopyWith<$Res> {
  _$AgendaItemCopyWithImpl(this._self, this._then);

  final AgendaItem _self;
  final $Res Function(AgendaItem) _then;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? discussion = null,Object? conclusion = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,discussion: null == discussion ? _self.discussion : discussion // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgendaItem].
extension AgendaItemPatterns on AgendaItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgendaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgendaItem value)  $default,){
final _that = this;
switch (_that) {
case _AgendaItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgendaItem value)?  $default,){
final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String discussion,  String? conclusion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that.title,_that.discussion,_that.conclusion);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String discussion,  String? conclusion)  $default,) {final _that = this;
switch (_that) {
case _AgendaItem():
return $default(_that.title,_that.discussion,_that.conclusion);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String discussion,  String? conclusion)?  $default,) {final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that.title,_that.discussion,_that.conclusion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgendaItem implements AgendaItem {
  const _AgendaItem({this.title = '', this.discussion = '', this.conclusion});
  factory _AgendaItem.fromJson(Map<String, dynamic> json) => _$AgendaItemFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String discussion;
@override final  String? conclusion;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgendaItemCopyWith<_AgendaItem> get copyWith => __$AgendaItemCopyWithImpl<_AgendaItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgendaItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgendaItem&&(identical(other.title, title) || other.title == title)&&(identical(other.discussion, discussion) || other.discussion == discussion)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,discussion,conclusion);

@override
String toString() {
  return 'AgendaItem(title: $title, discussion: $discussion, conclusion: $conclusion)';
}


}

/// @nodoc
abstract mixin class _$AgendaItemCopyWith<$Res> implements $AgendaItemCopyWith<$Res> {
  factory _$AgendaItemCopyWith(_AgendaItem value, $Res Function(_AgendaItem) _then) = __$AgendaItemCopyWithImpl;
@override @useResult
$Res call({
 String title, String discussion, String? conclusion
});




}
/// @nodoc
class __$AgendaItemCopyWithImpl<$Res>
    implements _$AgendaItemCopyWith<$Res> {
  __$AgendaItemCopyWithImpl(this._self, this._then);

  final _AgendaItem _self;
  final $Res Function(_AgendaItem) _then;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? discussion = null,Object? conclusion = freezed,}) {
  return _then(_AgendaItem(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,discussion: null == discussion ? _self.discussion : discussion // ignore: cast_nullable_to_non_nullable
as String,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ActionItem {

 String? get owner; String get task;@JsonKey(name: 'due_date') String? get dueDate;
/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionItemCopyWith<ActionItem> get copyWith => _$ActionItemCopyWithImpl<ActionItem>(this as ActionItem, _$identity);

  /// Serializes this ActionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionItem&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.task, task) || other.task == task)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,task,dueDate);

@override
String toString() {
  return 'ActionItem(owner: $owner, task: $task, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class $ActionItemCopyWith<$Res>  {
  factory $ActionItemCopyWith(ActionItem value, $Res Function(ActionItem) _then) = _$ActionItemCopyWithImpl;
@useResult
$Res call({
 String? owner, String task,@JsonKey(name: 'due_date') String? dueDate
});




}
/// @nodoc
class _$ActionItemCopyWithImpl<$Res>
    implements $ActionItemCopyWith<$Res> {
  _$ActionItemCopyWithImpl(this._self, this._then);

  final ActionItem _self;
  final $Res Function(ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = freezed,Object? task = null,Object? dueDate = freezed,}) {
  return _then(_self.copyWith(
owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionItem].
extension ActionItemPatterns on ActionItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionItem value)  $default,){
final _that = this;
switch (_that) {
case _ActionItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? owner,  String task, @JsonKey(name: 'due_date')  String? dueDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.owner,_that.task,_that.dueDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? owner,  String task, @JsonKey(name: 'due_date')  String? dueDate)  $default,) {final _that = this;
switch (_that) {
case _ActionItem():
return $default(_that.owner,_that.task,_that.dueDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? owner,  String task, @JsonKey(name: 'due_date')  String? dueDate)?  $default,) {final _that = this;
switch (_that) {
case _ActionItem() when $default != null:
return $default(_that.owner,_that.task,_that.dueDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionItem implements ActionItem {
  const _ActionItem({this.owner, this.task = '', @JsonKey(name: 'due_date') this.dueDate});
  factory _ActionItem.fromJson(Map<String, dynamic> json) => _$ActionItemFromJson(json);

@override final  String? owner;
@override@JsonKey() final  String task;
@override@JsonKey(name: 'due_date') final  String? dueDate;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionItemCopyWith<_ActionItem> get copyWith => __$ActionItemCopyWithImpl<_ActionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionItem&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.task, task) || other.task == task)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,task,dueDate);

@override
String toString() {
  return 'ActionItem(owner: $owner, task: $task, dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class _$ActionItemCopyWith<$Res> implements $ActionItemCopyWith<$Res> {
  factory _$ActionItemCopyWith(_ActionItem value, $Res Function(_ActionItem) _then) = __$ActionItemCopyWithImpl;
@override @useResult
$Res call({
 String? owner, String task,@JsonKey(name: 'due_date') String? dueDate
});




}
/// @nodoc
class __$ActionItemCopyWithImpl<$Res>
    implements _$ActionItemCopyWith<$Res> {
  __$ActionItemCopyWithImpl(this._self, this._then);

  final _ActionItem _self;
  final $Res Function(_ActionItem) _then;

/// Create a copy of ActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = freezed,Object? task = null,Object? dueDate = freezed,}) {
  return _then(_ActionItem(
owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String?,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
