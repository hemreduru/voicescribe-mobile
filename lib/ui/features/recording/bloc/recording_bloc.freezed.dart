// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recording_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecordingState {

 List<Transcript> get transcripts; List<TranscriptChunk> get allChunks; Transcript? get currentTranscript; List<TranscriptChunk> get currentChunks; bool get isRecording; bool get isPaused; int get durationSeconds; int get chunkCount; double get audioLevel; String get liveTranscriptPreview; String? get errorMessage; String? get userMessage; Set<String> get retryingChunkIds;
/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordingStateCopyWith<RecordingState> get copyWith => _$RecordingStateCopyWithImpl<RecordingState>(this as RecordingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordingState&&const DeepCollectionEquality().equals(other.transcripts, transcripts)&&const DeepCollectionEquality().equals(other.allChunks, allChunks)&&(identical(other.currentTranscript, currentTranscript) || other.currentTranscript == currentTranscript)&&const DeepCollectionEquality().equals(other.currentChunks, currentChunks)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.chunkCount, chunkCount) || other.chunkCount == chunkCount)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel)&&(identical(other.liveTranscriptPreview, liveTranscriptPreview) || other.liveTranscriptPreview == liveTranscriptPreview)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&const DeepCollectionEquality().equals(other.retryingChunkIds, retryingChunkIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(transcripts),const DeepCollectionEquality().hash(allChunks),currentTranscript,const DeepCollectionEquality().hash(currentChunks),isRecording,isPaused,durationSeconds,chunkCount,audioLevel,liveTranscriptPreview,errorMessage,userMessage,const DeepCollectionEquality().hash(retryingChunkIds));

@override
String toString() {
  return 'RecordingState(transcripts: $transcripts, allChunks: $allChunks, currentTranscript: $currentTranscript, currentChunks: $currentChunks, isRecording: $isRecording, isPaused: $isPaused, durationSeconds: $durationSeconds, chunkCount: $chunkCount, audioLevel: $audioLevel, liveTranscriptPreview: $liveTranscriptPreview, errorMessage: $errorMessage, userMessage: $userMessage, retryingChunkIds: $retryingChunkIds)';
}


}

/// @nodoc
abstract mixin class $RecordingStateCopyWith<$Res>  {
  factory $RecordingStateCopyWith(RecordingState value, $Res Function(RecordingState) _then) = _$RecordingStateCopyWithImpl;
@useResult
$Res call({
 List<Transcript> transcripts, List<TranscriptChunk> allChunks, Transcript? currentTranscript, List<TranscriptChunk> currentChunks, bool isRecording, bool isPaused, int durationSeconds, int chunkCount, double audioLevel, String liveTranscriptPreview, String? errorMessage, String? userMessage, Set<String> retryingChunkIds
});


$TranscriptCopyWith<$Res>? get currentTranscript;

}
/// @nodoc
class _$RecordingStateCopyWithImpl<$Res>
    implements $RecordingStateCopyWith<$Res> {
  _$RecordingStateCopyWithImpl(this._self, this._then);

  final RecordingState _self;
  final $Res Function(RecordingState) _then;

/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transcripts = null,Object? allChunks = null,Object? currentTranscript = freezed,Object? currentChunks = null,Object? isRecording = null,Object? isPaused = null,Object? durationSeconds = null,Object? chunkCount = null,Object? audioLevel = null,Object? liveTranscriptPreview = null,Object? errorMessage = freezed,Object? userMessage = freezed,Object? retryingChunkIds = null,}) {
  return _then(_self.copyWith(
transcripts: null == transcripts ? _self.transcripts : transcripts // ignore: cast_nullable_to_non_nullable
as List<Transcript>,allChunks: null == allChunks ? _self.allChunks : allChunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,currentTranscript: freezed == currentTranscript ? _self.currentTranscript : currentTranscript // ignore: cast_nullable_to_non_nullable
as Transcript?,currentChunks: null == currentChunks ? _self.currentChunks : currentChunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,chunkCount: null == chunkCount ? _self.chunkCount : chunkCount // ignore: cast_nullable_to_non_nullable
as int,audioLevel: null == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double,liveTranscriptPreview: null == liveTranscriptPreview ? _self.liveTranscriptPreview : liveTranscriptPreview // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,retryingChunkIds: null == retryingChunkIds ? _self.retryingChunkIds : retryingChunkIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}
/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TranscriptCopyWith<$Res>? get currentTranscript {
    if (_self.currentTranscript == null) {
    return null;
  }

  return $TranscriptCopyWith<$Res>(_self.currentTranscript!, (value) {
    return _then(_self.copyWith(currentTranscript: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecordingState].
extension RecordingStatePatterns on RecordingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecordingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecordingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecordingState value)  $default,){
final _that = this;
switch (_that) {
case _RecordingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecordingState value)?  $default,){
final _that = this;
switch (_that) {
case _RecordingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transcript> transcripts,  List<TranscriptChunk> allChunks,  Transcript? currentTranscript,  List<TranscriptChunk> currentChunks,  bool isRecording,  bool isPaused,  int durationSeconds,  int chunkCount,  double audioLevel,  String liveTranscriptPreview,  String? errorMessage,  String? userMessage,  Set<String> retryingChunkIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecordingState() when $default != null:
return $default(_that.transcripts,_that.allChunks,_that.currentTranscript,_that.currentChunks,_that.isRecording,_that.isPaused,_that.durationSeconds,_that.chunkCount,_that.audioLevel,_that.liveTranscriptPreview,_that.errorMessage,_that.userMessage,_that.retryingChunkIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transcript> transcripts,  List<TranscriptChunk> allChunks,  Transcript? currentTranscript,  List<TranscriptChunk> currentChunks,  bool isRecording,  bool isPaused,  int durationSeconds,  int chunkCount,  double audioLevel,  String liveTranscriptPreview,  String? errorMessage,  String? userMessage,  Set<String> retryingChunkIds)  $default,) {final _that = this;
switch (_that) {
case _RecordingState():
return $default(_that.transcripts,_that.allChunks,_that.currentTranscript,_that.currentChunks,_that.isRecording,_that.isPaused,_that.durationSeconds,_that.chunkCount,_that.audioLevel,_that.liveTranscriptPreview,_that.errorMessage,_that.userMessage,_that.retryingChunkIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transcript> transcripts,  List<TranscriptChunk> allChunks,  Transcript? currentTranscript,  List<TranscriptChunk> currentChunks,  bool isRecording,  bool isPaused,  int durationSeconds,  int chunkCount,  double audioLevel,  String liveTranscriptPreview,  String? errorMessage,  String? userMessage,  Set<String> retryingChunkIds)?  $default,) {final _that = this;
switch (_that) {
case _RecordingState() when $default != null:
return $default(_that.transcripts,_that.allChunks,_that.currentTranscript,_that.currentChunks,_that.isRecording,_that.isPaused,_that.durationSeconds,_that.chunkCount,_that.audioLevel,_that.liveTranscriptPreview,_that.errorMessage,_that.userMessage,_that.retryingChunkIds);case _:
  return null;

}
}

}

/// @nodoc


class _RecordingState implements RecordingState {
  const _RecordingState({final  List<Transcript> transcripts = const <Transcript>[], final  List<TranscriptChunk> allChunks = const <TranscriptChunk>[], this.currentTranscript, final  List<TranscriptChunk> currentChunks = const <TranscriptChunk>[], this.isRecording = false, this.isPaused = false, this.durationSeconds = 0, this.chunkCount = 0, this.audioLevel = 0.0, this.liveTranscriptPreview = '', this.errorMessage, this.userMessage, final  Set<String> retryingChunkIds = const <String>{}}): _transcripts = transcripts,_allChunks = allChunks,_currentChunks = currentChunks,_retryingChunkIds = retryingChunkIds;
  

 final  List<Transcript> _transcripts;
@override@JsonKey() List<Transcript> get transcripts {
  if (_transcripts is EqualUnmodifiableListView) return _transcripts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcripts);
}

 final  List<TranscriptChunk> _allChunks;
@override@JsonKey() List<TranscriptChunk> get allChunks {
  if (_allChunks is EqualUnmodifiableListView) return _allChunks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allChunks);
}

@override final  Transcript? currentTranscript;
 final  List<TranscriptChunk> _currentChunks;
@override@JsonKey() List<TranscriptChunk> get currentChunks {
  if (_currentChunks is EqualUnmodifiableListView) return _currentChunks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_currentChunks);
}

@override@JsonKey() final  bool isRecording;
@override@JsonKey() final  bool isPaused;
@override@JsonKey() final  int durationSeconds;
@override@JsonKey() final  int chunkCount;
@override@JsonKey() final  double audioLevel;
@override@JsonKey() final  String liveTranscriptPreview;
@override final  String? errorMessage;
@override final  String? userMessage;
 final  Set<String> _retryingChunkIds;
@override@JsonKey() Set<String> get retryingChunkIds {
  if (_retryingChunkIds is EqualUnmodifiableSetView) return _retryingChunkIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_retryingChunkIds);
}


/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecordingStateCopyWith<_RecordingState> get copyWith => __$RecordingStateCopyWithImpl<_RecordingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecordingState&&const DeepCollectionEquality().equals(other._transcripts, _transcripts)&&const DeepCollectionEquality().equals(other._allChunks, _allChunks)&&(identical(other.currentTranscript, currentTranscript) || other.currentTranscript == currentTranscript)&&const DeepCollectionEquality().equals(other._currentChunks, _currentChunks)&&(identical(other.isRecording, isRecording) || other.isRecording == isRecording)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.chunkCount, chunkCount) || other.chunkCount == chunkCount)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel)&&(identical(other.liveTranscriptPreview, liveTranscriptPreview) || other.liveTranscriptPreview == liveTranscriptPreview)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.userMessage, userMessage) || other.userMessage == userMessage)&&const DeepCollectionEquality().equals(other._retryingChunkIds, _retryingChunkIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcripts),const DeepCollectionEquality().hash(_allChunks),currentTranscript,const DeepCollectionEquality().hash(_currentChunks),isRecording,isPaused,durationSeconds,chunkCount,audioLevel,liveTranscriptPreview,errorMessage,userMessage,const DeepCollectionEquality().hash(_retryingChunkIds));

@override
String toString() {
  return 'RecordingState(transcripts: $transcripts, allChunks: $allChunks, currentTranscript: $currentTranscript, currentChunks: $currentChunks, isRecording: $isRecording, isPaused: $isPaused, durationSeconds: $durationSeconds, chunkCount: $chunkCount, audioLevel: $audioLevel, liveTranscriptPreview: $liveTranscriptPreview, errorMessage: $errorMessage, userMessage: $userMessage, retryingChunkIds: $retryingChunkIds)';
}


}

/// @nodoc
abstract mixin class _$RecordingStateCopyWith<$Res> implements $RecordingStateCopyWith<$Res> {
  factory _$RecordingStateCopyWith(_RecordingState value, $Res Function(_RecordingState) _then) = __$RecordingStateCopyWithImpl;
@override @useResult
$Res call({
 List<Transcript> transcripts, List<TranscriptChunk> allChunks, Transcript? currentTranscript, List<TranscriptChunk> currentChunks, bool isRecording, bool isPaused, int durationSeconds, int chunkCount, double audioLevel, String liveTranscriptPreview, String? errorMessage, String? userMessage, Set<String> retryingChunkIds
});


@override $TranscriptCopyWith<$Res>? get currentTranscript;

}
/// @nodoc
class __$RecordingStateCopyWithImpl<$Res>
    implements _$RecordingStateCopyWith<$Res> {
  __$RecordingStateCopyWithImpl(this._self, this._then);

  final _RecordingState _self;
  final $Res Function(_RecordingState) _then;

/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcripts = null,Object? allChunks = null,Object? currentTranscript = freezed,Object? currentChunks = null,Object? isRecording = null,Object? isPaused = null,Object? durationSeconds = null,Object? chunkCount = null,Object? audioLevel = null,Object? liveTranscriptPreview = null,Object? errorMessage = freezed,Object? userMessage = freezed,Object? retryingChunkIds = null,}) {
  return _then(_RecordingState(
transcripts: null == transcripts ? _self._transcripts : transcripts // ignore: cast_nullable_to_non_nullable
as List<Transcript>,allChunks: null == allChunks ? _self._allChunks : allChunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,currentTranscript: freezed == currentTranscript ? _self.currentTranscript : currentTranscript // ignore: cast_nullable_to_non_nullable
as Transcript?,currentChunks: null == currentChunks ? _self._currentChunks : currentChunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,isRecording: null == isRecording ? _self.isRecording : isRecording // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,chunkCount: null == chunkCount ? _self.chunkCount : chunkCount // ignore: cast_nullable_to_non_nullable
as int,audioLevel: null == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double,liveTranscriptPreview: null == liveTranscriptPreview ? _self.liveTranscriptPreview : liveTranscriptPreview // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,userMessage: freezed == userMessage ? _self.userMessage : userMessage // ignore: cast_nullable_to_non_nullable
as String?,retryingChunkIds: null == retryingChunkIds ? _self._retryingChunkIds : retryingChunkIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

/// Create a copy of RecordingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TranscriptCopyWith<$Res>? get currentTranscript {
    if (_self.currentTranscript == null) {
    return null;
  }

  return $TranscriptCopyWith<$Res>(_self.currentTranscript!, (value) {
    return _then(_self.copyWith(currentTranscript: value));
  });
}
}

// dart format on
