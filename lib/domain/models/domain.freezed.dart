// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'domain.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthSessionState {

 String get userId; String get email; String get accessToken; String? get refreshToken; DateTime? get expiresAt;
/// Create a copy of AuthSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionStateCopyWith<AuthSessionState> get copyWith => _$AuthSessionStateCopyWithImpl<AuthSessionState>(this as AuthSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSessionState&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,email,accessToken,refreshToken,expiresAt);

@override
String toString() {
  return 'AuthSessionState(userId: $userId, email: $email, accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $AuthSessionStateCopyWith<$Res>  {
  factory $AuthSessionStateCopyWith(AuthSessionState value, $Res Function(AuthSessionState) _then) = _$AuthSessionStateCopyWithImpl;
@useResult
$Res call({
 String userId, String email, String accessToken, String? refreshToken, DateTime? expiresAt
});




}
/// @nodoc
class _$AuthSessionStateCopyWithImpl<$Res>
    implements $AuthSessionStateCopyWith<$Res> {
  _$AuthSessionStateCopyWithImpl(this._self, this._then);

  final AuthSessionState _self;
  final $Res Function(AuthSessionState) _then;

/// Create a copy of AuthSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? email = null,Object? accessToken = null,Object? refreshToken = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthSessionState].
extension AuthSessionStatePatterns on AuthSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSessionState value)  $default,){
final _that = this;
switch (_that) {
case _AuthSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String email,  String accessToken,  String? refreshToken,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSessionState() when $default != null:
return $default(_that.userId,_that.email,_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String email,  String accessToken,  String? refreshToken,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _AuthSessionState():
return $default(_that.userId,_that.email,_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String email,  String accessToken,  String? refreshToken,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _AuthSessionState() when $default != null:
return $default(_that.userId,_that.email,_that.accessToken,_that.refreshToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _AuthSessionState extends AuthSessionState {
  const _AuthSessionState({required this.userId, required this.email, required this.accessToken, required this.refreshToken, required this.expiresAt}): super._();
  

@override final  String userId;
@override final  String email;
@override final  String accessToken;
@override final  String? refreshToken;
@override final  DateTime? expiresAt;

/// Create a copy of AuthSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionStateCopyWith<_AuthSessionState> get copyWith => __$AuthSessionStateCopyWithImpl<_AuthSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSessionState&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,email,accessToken,refreshToken,expiresAt);

@override
String toString() {
  return 'AuthSessionState(userId: $userId, email: $email, accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionStateCopyWith<$Res> implements $AuthSessionStateCopyWith<$Res> {
  factory _$AuthSessionStateCopyWith(_AuthSessionState value, $Res Function(_AuthSessionState) _then) = __$AuthSessionStateCopyWithImpl;
@override @useResult
$Res call({
 String userId, String email, String accessToken, String? refreshToken, DateTime? expiresAt
});




}
/// @nodoc
class __$AuthSessionStateCopyWithImpl<$Res>
    implements _$AuthSessionStateCopyWith<$Res> {
  __$AuthSessionStateCopyWithImpl(this._self, this._then);

  final _AuthSessionState _self;
  final $Res Function(_AuthSessionState) _then;

/// Create a copy of AuthSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? email = null,Object? accessToken = null,Object? refreshToken = freezed,Object? expiresAt = freezed,}) {
  return _then(_AuthSessionState(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$Transcript {

 String get id; String get localId; String? get title; int get durationSeconds; TranscriptStatus get status; DateTime? get recordedAt; DateTime get createdAt; DateTime get updatedAt; String? get userId; String? get remoteId; SyncStatus get syncStatus; DateTime? get lastSyncedAt; String? get syncError; DateTime? get deletedAt;
/// Create a copy of Transcript
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptCopyWith<Transcript> get copyWith => _$TranscriptCopyWithImpl<Transcript>(this as Transcript, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transcript&&(identical(other.id, id) || other.id == id)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.title, title) || other.title == title)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.status, status) || other.status == status)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,localId,title,durationSeconds,status,recordedAt,createdAt,updatedAt,userId,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'Transcript(id: $id, localId: $localId, title: $title, durationSeconds: $durationSeconds, status: $status, recordedAt: $recordedAt, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $TranscriptCopyWith<$Res>  {
  factory $TranscriptCopyWith(Transcript value, $Res Function(Transcript) _then) = _$TranscriptCopyWithImpl;
@useResult
$Res call({
 String id, String localId, String? title, int durationSeconds, TranscriptStatus status, DateTime? recordedAt, DateTime createdAt, DateTime updatedAt, String? userId, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class _$TranscriptCopyWithImpl<$Res>
    implements $TranscriptCopyWith<$Res> {
  _$TranscriptCopyWithImpl(this._self, this._then);

  final Transcript _self;
  final $Res Function(Transcript) _then;

/// Create a copy of Transcript
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? localId = null,Object? title = freezed,Object? durationSeconds = null,Object? status = null,Object? recordedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? userId = freezed,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TranscriptStatus,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transcript].
extension TranscriptPatterns on Transcript {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transcript value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transcript() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transcript value)  $default,){
final _that = this;
switch (_that) {
case _Transcript():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transcript value)?  $default,){
final _that = this;
switch (_that) {
case _Transcript() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String localId,  String? title,  int durationSeconds,  TranscriptStatus status,  DateTime? recordedAt,  DateTime createdAt,  DateTime updatedAt,  String? userId,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transcript() when $default != null:
return $default(_that.id,_that.localId,_that.title,_that.durationSeconds,_that.status,_that.recordedAt,_that.createdAt,_that.updatedAt,_that.userId,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String localId,  String? title,  int durationSeconds,  TranscriptStatus status,  DateTime? recordedAt,  DateTime createdAt,  DateTime updatedAt,  String? userId,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Transcript():
return $default(_that.id,_that.localId,_that.title,_that.durationSeconds,_that.status,_that.recordedAt,_that.createdAt,_that.updatedAt,_that.userId,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String localId,  String? title,  int durationSeconds,  TranscriptStatus status,  DateTime? recordedAt,  DateTime createdAt,  DateTime updatedAt,  String? userId,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Transcript() when $default != null:
return $default(_that.id,_that.localId,_that.title,_that.durationSeconds,_that.status,_that.recordedAt,_that.createdAt,_that.updatedAt,_that.userId,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Transcript implements Transcript {
  const _Transcript({required this.id, required this.localId, required this.title, required this.durationSeconds, required this.status, required this.recordedAt, required this.createdAt, required this.updatedAt, this.userId, this.remoteId, this.syncStatus = SyncStatus.pending, this.lastSyncedAt, this.syncError, this.deletedAt});
  

@override final  String id;
@override final  String localId;
@override final  String? title;
@override final  int durationSeconds;
@override final  TranscriptStatus status;
@override final  DateTime? recordedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? userId;
@override final  String? remoteId;
@override@JsonKey() final  SyncStatus syncStatus;
@override final  DateTime? lastSyncedAt;
@override final  String? syncError;
@override final  DateTime? deletedAt;

/// Create a copy of Transcript
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptCopyWith<_Transcript> get copyWith => __$TranscriptCopyWithImpl<_Transcript>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transcript&&(identical(other.id, id) || other.id == id)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.title, title) || other.title == title)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.status, status) || other.status == status)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,localId,title,durationSeconds,status,recordedAt,createdAt,updatedAt,userId,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'Transcript(id: $id, localId: $localId, title: $title, durationSeconds: $durationSeconds, status: $status, recordedAt: $recordedAt, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$TranscriptCopyWith<$Res> implements $TranscriptCopyWith<$Res> {
  factory _$TranscriptCopyWith(_Transcript value, $Res Function(_Transcript) _then) = __$TranscriptCopyWithImpl;
@override @useResult
$Res call({
 String id, String localId, String? title, int durationSeconds, TranscriptStatus status, DateTime? recordedAt, DateTime createdAt, DateTime updatedAt, String? userId, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class __$TranscriptCopyWithImpl<$Res>
    implements _$TranscriptCopyWith<$Res> {
  __$TranscriptCopyWithImpl(this._self, this._then);

  final _Transcript _self;
  final $Res Function(_Transcript) _then;

/// Create a copy of Transcript
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? localId = null,Object? title = freezed,Object? durationSeconds = null,Object? status = null,Object? recordedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? userId = freezed,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_Transcript(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TranscriptStatus,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$TranscriptChunk {

 String get id; String get transcriptId; int get chunkIndex; String get text; String? get audioPath; DateTime? get recordedAt; double get startTime; double get endTime; double? get confidence; String? get transcriptionError; double? get audioLevel; String? get remoteId; SyncStatus get syncStatus; DateTime? get lastSyncedAt; String? get syncError; DateTime? get deletedAt;
/// Create a copy of TranscriptChunk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptChunkCopyWith<TranscriptChunk> get copyWith => _$TranscriptChunkCopyWithImpl<TranscriptChunk>(this as TranscriptChunk, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscriptChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.transcriptId, transcriptId) || other.transcriptId == transcriptId)&&(identical(other.chunkIndex, chunkIndex) || other.chunkIndex == chunkIndex)&&(identical(other.text, text) || other.text == text)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.transcriptionError, transcriptionError) || other.transcriptionError == transcriptionError)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,transcriptId,chunkIndex,text,audioPath,recordedAt,startTime,endTime,confidence,transcriptionError,audioLevel,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'TranscriptChunk(id: $id, transcriptId: $transcriptId, chunkIndex: $chunkIndex, text: $text, audioPath: $audioPath, recordedAt: $recordedAt, startTime: $startTime, endTime: $endTime, confidence: $confidence, transcriptionError: $transcriptionError, audioLevel: $audioLevel, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $TranscriptChunkCopyWith<$Res>  {
  factory $TranscriptChunkCopyWith(TranscriptChunk value, $Res Function(TranscriptChunk) _then) = _$TranscriptChunkCopyWithImpl;
@useResult
$Res call({
 String id, String transcriptId, int chunkIndex, String text, String? audioPath, DateTime? recordedAt, double startTime, double endTime, double? confidence, String? transcriptionError, double? audioLevel, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class _$TranscriptChunkCopyWithImpl<$Res>
    implements $TranscriptChunkCopyWith<$Res> {
  _$TranscriptChunkCopyWithImpl(this._self, this._then);

  final TranscriptChunk _self;
  final $Res Function(TranscriptChunk) _then;

/// Create a copy of TranscriptChunk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? transcriptId = null,Object? chunkIndex = null,Object? text = null,Object? audioPath = freezed,Object? recordedAt = freezed,Object? startTime = null,Object? endTime = null,Object? confidence = freezed,Object? transcriptionError = freezed,Object? audioLevel = freezed,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transcriptId: null == transcriptId ? _self.transcriptId : transcriptId // ignore: cast_nullable_to_non_nullable
as String,chunkIndex: null == chunkIndex ? _self.chunkIndex : chunkIndex // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as double,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as double,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,transcriptionError: freezed == transcriptionError ? _self.transcriptionError : transcriptionError // ignore: cast_nullable_to_non_nullable
as String?,audioLevel: freezed == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double?,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TranscriptChunk].
extension TranscriptChunkPatterns on TranscriptChunk {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscriptChunk value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscriptChunk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscriptChunk value)  $default,){
final _that = this;
switch (_that) {
case _TranscriptChunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscriptChunk value)?  $default,){
final _that = this;
switch (_that) {
case _TranscriptChunk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String transcriptId,  int chunkIndex,  String text,  String? audioPath,  DateTime? recordedAt,  double startTime,  double endTime,  double? confidence,  String? transcriptionError,  double? audioLevel,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranscriptChunk() when $default != null:
return $default(_that.id,_that.transcriptId,_that.chunkIndex,_that.text,_that.audioPath,_that.recordedAt,_that.startTime,_that.endTime,_that.confidence,_that.transcriptionError,_that.audioLevel,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String transcriptId,  int chunkIndex,  String text,  String? audioPath,  DateTime? recordedAt,  double startTime,  double endTime,  double? confidence,  String? transcriptionError,  double? audioLevel,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _TranscriptChunk():
return $default(_that.id,_that.transcriptId,_that.chunkIndex,_that.text,_that.audioPath,_that.recordedAt,_that.startTime,_that.endTime,_that.confidence,_that.transcriptionError,_that.audioLevel,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String transcriptId,  int chunkIndex,  String text,  String? audioPath,  DateTime? recordedAt,  double startTime,  double endTime,  double? confidence,  String? transcriptionError,  double? audioLevel,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _TranscriptChunk() when $default != null:
return $default(_that.id,_that.transcriptId,_that.chunkIndex,_that.text,_that.audioPath,_that.recordedAt,_that.startTime,_that.endTime,_that.confidence,_that.transcriptionError,_that.audioLevel,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TranscriptChunk implements TranscriptChunk {
  const _TranscriptChunk({required this.id, required this.transcriptId, required this.chunkIndex, required this.text, required this.audioPath, required this.recordedAt, required this.startTime, required this.endTime, required this.confidence, required this.transcriptionError, this.audioLevel, this.remoteId, this.syncStatus = SyncStatus.pending, this.lastSyncedAt, this.syncError, this.deletedAt});
  

@override final  String id;
@override final  String transcriptId;
@override final  int chunkIndex;
@override final  String text;
@override final  String? audioPath;
@override final  DateTime? recordedAt;
@override final  double startTime;
@override final  double endTime;
@override final  double? confidence;
@override final  String? transcriptionError;
@override final  double? audioLevel;
@override final  String? remoteId;
@override@JsonKey() final  SyncStatus syncStatus;
@override final  DateTime? lastSyncedAt;
@override final  String? syncError;
@override final  DateTime? deletedAt;

/// Create a copy of TranscriptChunk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptChunkCopyWith<_TranscriptChunk> get copyWith => __$TranscriptChunkCopyWithImpl<_TranscriptChunk>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscriptChunk&&(identical(other.id, id) || other.id == id)&&(identical(other.transcriptId, transcriptId) || other.transcriptId == transcriptId)&&(identical(other.chunkIndex, chunkIndex) || other.chunkIndex == chunkIndex)&&(identical(other.text, text) || other.text == text)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.transcriptionError, transcriptionError) || other.transcriptionError == transcriptionError)&&(identical(other.audioLevel, audioLevel) || other.audioLevel == audioLevel)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,transcriptId,chunkIndex,text,audioPath,recordedAt,startTime,endTime,confidence,transcriptionError,audioLevel,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'TranscriptChunk(id: $id, transcriptId: $transcriptId, chunkIndex: $chunkIndex, text: $text, audioPath: $audioPath, recordedAt: $recordedAt, startTime: $startTime, endTime: $endTime, confidence: $confidence, transcriptionError: $transcriptionError, audioLevel: $audioLevel, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$TranscriptChunkCopyWith<$Res> implements $TranscriptChunkCopyWith<$Res> {
  factory _$TranscriptChunkCopyWith(_TranscriptChunk value, $Res Function(_TranscriptChunk) _then) = __$TranscriptChunkCopyWithImpl;
@override @useResult
$Res call({
 String id, String transcriptId, int chunkIndex, String text, String? audioPath, DateTime? recordedAt, double startTime, double endTime, double? confidence, String? transcriptionError, double? audioLevel, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class __$TranscriptChunkCopyWithImpl<$Res>
    implements _$TranscriptChunkCopyWith<$Res> {
  __$TranscriptChunkCopyWithImpl(this._self, this._then);

  final _TranscriptChunk _self;
  final $Res Function(_TranscriptChunk) _then;

/// Create a copy of TranscriptChunk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? transcriptId = null,Object? chunkIndex = null,Object? text = null,Object? audioPath = freezed,Object? recordedAt = freezed,Object? startTime = null,Object? endTime = null,Object? confidence = freezed,Object? transcriptionError = freezed,Object? audioLevel = freezed,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_TranscriptChunk(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transcriptId: null == transcriptId ? _self.transcriptId : transcriptId // ignore: cast_nullable_to_non_nullable
as String,chunkIndex: null == chunkIndex ? _self.chunkIndex : chunkIndex // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: freezed == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as double,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as double,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,transcriptionError: freezed == transcriptionError ? _self.transcriptionError : transcriptionError // ignore: cast_nullable_to_non_nullable
as String?,audioLevel: freezed == audioLevel ? _self.audioLevel : audioLevel // ignore: cast_nullable_to_non_nullable
as double?,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$Summary {

 String get id; String get transcriptId; String get providerKey; String get model; String get summaryText; int? get tokenCount; int? get processingTimeMs; DateTime get createdAt; String? get remoteId; SyncStatus get syncStatus; DateTime? get lastSyncedAt; String? get syncError; DateTime? get deletedAt;
/// Create a copy of Summary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryCopyWith<Summary> get copyWith => _$SummaryCopyWithImpl<Summary>(this as Summary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Summary&&(identical(other.id, id) || other.id == id)&&(identical(other.transcriptId, transcriptId) || other.transcriptId == transcriptId)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.summaryText, summaryText) || other.summaryText == summaryText)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,transcriptId,providerKey,model,summaryText,tokenCount,processingTimeMs,createdAt,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'Summary(id: $id, transcriptId: $transcriptId, providerKey: $providerKey, model: $model, summaryText: $summaryText, tokenCount: $tokenCount, processingTimeMs: $processingTimeMs, createdAt: $createdAt, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $SummaryCopyWith<$Res>  {
  factory $SummaryCopyWith(Summary value, $Res Function(Summary) _then) = _$SummaryCopyWithImpl;
@useResult
$Res call({
 String id, String transcriptId, String providerKey, String model, String summaryText, int? tokenCount, int? processingTimeMs, DateTime createdAt, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class _$SummaryCopyWithImpl<$Res>
    implements $SummaryCopyWith<$Res> {
  _$SummaryCopyWithImpl(this._self, this._then);

  final Summary _self;
  final $Res Function(Summary) _then;

/// Create a copy of Summary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? transcriptId = null,Object? providerKey = null,Object? model = null,Object? summaryText = null,Object? tokenCount = freezed,Object? processingTimeMs = freezed,Object? createdAt = null,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transcriptId: null == transcriptId ? _self.transcriptId : transcriptId // ignore: cast_nullable_to_non_nullable
as String,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,summaryText: null == summaryText ? _self.summaryText : summaryText // ignore: cast_nullable_to_non_nullable
as String,tokenCount: freezed == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as int?,processingTimeMs: freezed == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Summary].
extension SummaryPatterns on Summary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Summary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Summary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Summary value)  $default,){
final _that = this;
switch (_that) {
case _Summary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Summary value)?  $default,){
final _that = this;
switch (_that) {
case _Summary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String transcriptId,  String providerKey,  String model,  String summaryText,  int? tokenCount,  int? processingTimeMs,  DateTime createdAt,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Summary() when $default != null:
return $default(_that.id,_that.transcriptId,_that.providerKey,_that.model,_that.summaryText,_that.tokenCount,_that.processingTimeMs,_that.createdAt,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String transcriptId,  String providerKey,  String model,  String summaryText,  int? tokenCount,  int? processingTimeMs,  DateTime createdAt,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Summary():
return $default(_that.id,_that.transcriptId,_that.providerKey,_that.model,_that.summaryText,_that.tokenCount,_that.processingTimeMs,_that.createdAt,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String transcriptId,  String providerKey,  String model,  String summaryText,  int? tokenCount,  int? processingTimeMs,  DateTime createdAt,  String? remoteId,  SyncStatus syncStatus,  DateTime? lastSyncedAt,  String? syncError,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Summary() when $default != null:
return $default(_that.id,_that.transcriptId,_that.providerKey,_that.model,_that.summaryText,_that.tokenCount,_that.processingTimeMs,_that.createdAt,_that.remoteId,_that.syncStatus,_that.lastSyncedAt,_that.syncError,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Summary implements Summary {
  const _Summary({required this.id, required this.transcriptId, required this.providerKey, required this.model, required this.summaryText, required this.tokenCount, required this.processingTimeMs, required this.createdAt, this.remoteId, this.syncStatus = SyncStatus.pending, this.lastSyncedAt, this.syncError, this.deletedAt});
  

@override final  String id;
@override final  String transcriptId;
@override final  String providerKey;
@override final  String model;
@override final  String summaryText;
@override final  int? tokenCount;
@override final  int? processingTimeMs;
@override final  DateTime createdAt;
@override final  String? remoteId;
@override@JsonKey() final  SyncStatus syncStatus;
@override final  DateTime? lastSyncedAt;
@override final  String? syncError;
@override final  DateTime? deletedAt;

/// Create a copy of Summary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SummaryCopyWith<_Summary> get copyWith => __$SummaryCopyWithImpl<_Summary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Summary&&(identical(other.id, id) || other.id == id)&&(identical(other.transcriptId, transcriptId) || other.transcriptId == transcriptId)&&(identical(other.providerKey, providerKey) || other.providerKey == providerKey)&&(identical(other.model, model) || other.model == model)&&(identical(other.summaryText, summaryText) || other.summaryText == summaryText)&&(identical(other.tokenCount, tokenCount) || other.tokenCount == tokenCount)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.remoteId, remoteId) || other.remoteId == remoteId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.syncError, syncError) || other.syncError == syncError)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,transcriptId,providerKey,model,summaryText,tokenCount,processingTimeMs,createdAt,remoteId,syncStatus,lastSyncedAt,syncError,deletedAt);

@override
String toString() {
  return 'Summary(id: $id, transcriptId: $transcriptId, providerKey: $providerKey, model: $model, summaryText: $summaryText, tokenCount: $tokenCount, processingTimeMs: $processingTimeMs, createdAt: $createdAt, remoteId: $remoteId, syncStatus: $syncStatus, lastSyncedAt: $lastSyncedAt, syncError: $syncError, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$SummaryCopyWith<$Res> implements $SummaryCopyWith<$Res> {
  factory _$SummaryCopyWith(_Summary value, $Res Function(_Summary) _then) = __$SummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String transcriptId, String providerKey, String model, String summaryText, int? tokenCount, int? processingTimeMs, DateTime createdAt, String? remoteId, SyncStatus syncStatus, DateTime? lastSyncedAt, String? syncError, DateTime? deletedAt
});




}
/// @nodoc
class __$SummaryCopyWithImpl<$Res>
    implements _$SummaryCopyWith<$Res> {
  __$SummaryCopyWithImpl(this._self, this._then);

  final _Summary _self;
  final $Res Function(_Summary) _then;

/// Create a copy of Summary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? transcriptId = null,Object? providerKey = null,Object? model = null,Object? summaryText = null,Object? tokenCount = freezed,Object? processingTimeMs = freezed,Object? createdAt = null,Object? remoteId = freezed,Object? syncStatus = null,Object? lastSyncedAt = freezed,Object? syncError = freezed,Object? deletedAt = freezed,}) {
  return _then(_Summary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transcriptId: null == transcriptId ? _self.transcriptId : transcriptId // ignore: cast_nullable_to_non_nullable
as String,providerKey: null == providerKey ? _self.providerKey : providerKey // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,summaryText: null == summaryText ? _self.summaryText : summaryText // ignore: cast_nullable_to_non_nullable
as String,tokenCount: freezed == tokenCount ? _self.tokenCount : tokenCount // ignore: cast_nullable_to_non_nullable
as int?,processingTimeMs: freezed == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,remoteId: freezed == remoteId ? _self.remoteId : remoteId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncError: freezed == syncError ? _self.syncError : syncError // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AppPreferences {

 String get summaryProvider; String get summaryLength; String get themeMode; String get localePreference; String get transcriptionModel;
/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppPreferencesCopyWith<AppPreferences> get copyWith => _$AppPreferencesCopyWithImpl<AppPreferences>(this as AppPreferences, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppPreferences&&(identical(other.summaryProvider, summaryProvider) || other.summaryProvider == summaryProvider)&&(identical(other.summaryLength, summaryLength) || other.summaryLength == summaryLength)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localePreference, localePreference) || other.localePreference == localePreference)&&(identical(other.transcriptionModel, transcriptionModel) || other.transcriptionModel == transcriptionModel));
}


@override
int get hashCode => Object.hash(runtimeType,summaryProvider,summaryLength,themeMode,localePreference,transcriptionModel);

@override
String toString() {
  return 'AppPreferences(summaryProvider: $summaryProvider, summaryLength: $summaryLength, themeMode: $themeMode, localePreference: $localePreference, transcriptionModel: $transcriptionModel)';
}


}

/// @nodoc
abstract mixin class $AppPreferencesCopyWith<$Res>  {
  factory $AppPreferencesCopyWith(AppPreferences value, $Res Function(AppPreferences) _then) = _$AppPreferencesCopyWithImpl;
@useResult
$Res call({
 String summaryProvider, String summaryLength, String themeMode, String localePreference, String transcriptionModel
});




}
/// @nodoc
class _$AppPreferencesCopyWithImpl<$Res>
    implements $AppPreferencesCopyWith<$Res> {
  _$AppPreferencesCopyWithImpl(this._self, this._then);

  final AppPreferences _self;
  final $Res Function(AppPreferences) _then;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summaryProvider = null,Object? summaryLength = null,Object? themeMode = null,Object? localePreference = null,Object? transcriptionModel = null,}) {
  return _then(_self.copyWith(
summaryProvider: null == summaryProvider ? _self.summaryProvider : summaryProvider // ignore: cast_nullable_to_non_nullable
as String,summaryLength: null == summaryLength ? _self.summaryLength : summaryLength // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,localePreference: null == localePreference ? _self.localePreference : localePreference // ignore: cast_nullable_to_non_nullable
as String,transcriptionModel: null == transcriptionModel ? _self.transcriptionModel : transcriptionModel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppPreferences].
extension AppPreferencesPatterns on AppPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppPreferences value)  $default,){
final _that = this;
switch (_that) {
case _AppPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summaryProvider,  String summaryLength,  String themeMode,  String localePreference,  String transcriptionModel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
return $default(_that.summaryProvider,_that.summaryLength,_that.themeMode,_that.localePreference,_that.transcriptionModel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summaryProvider,  String summaryLength,  String themeMode,  String localePreference,  String transcriptionModel)  $default,) {final _that = this;
switch (_that) {
case _AppPreferences():
return $default(_that.summaryProvider,_that.summaryLength,_that.themeMode,_that.localePreference,_that.transcriptionModel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summaryProvider,  String summaryLength,  String themeMode,  String localePreference,  String transcriptionModel)?  $default,) {final _that = this;
switch (_that) {
case _AppPreferences() when $default != null:
return $default(_that.summaryProvider,_that.summaryLength,_that.themeMode,_that.localePreference,_that.transcriptionModel);case _:
  return null;

}
}

}

/// @nodoc


class _AppPreferences extends AppPreferences {
  const _AppPreferences({this.summaryProvider = 'local', this.summaryLength = 'medium', this.themeMode = 'system', this.localePreference = 'system', this.transcriptionModel = 'base'}): super._();
  

@override@JsonKey() final  String summaryProvider;
@override@JsonKey() final  String summaryLength;
@override@JsonKey() final  String themeMode;
@override@JsonKey() final  String localePreference;
@override@JsonKey() final  String transcriptionModel;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppPreferencesCopyWith<_AppPreferences> get copyWith => __$AppPreferencesCopyWithImpl<_AppPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppPreferences&&(identical(other.summaryProvider, summaryProvider) || other.summaryProvider == summaryProvider)&&(identical(other.summaryLength, summaryLength) || other.summaryLength == summaryLength)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localePreference, localePreference) || other.localePreference == localePreference)&&(identical(other.transcriptionModel, transcriptionModel) || other.transcriptionModel == transcriptionModel));
}


@override
int get hashCode => Object.hash(runtimeType,summaryProvider,summaryLength,themeMode,localePreference,transcriptionModel);

@override
String toString() {
  return 'AppPreferences(summaryProvider: $summaryProvider, summaryLength: $summaryLength, themeMode: $themeMode, localePreference: $localePreference, transcriptionModel: $transcriptionModel)';
}


}

/// @nodoc
abstract mixin class _$AppPreferencesCopyWith<$Res> implements $AppPreferencesCopyWith<$Res> {
  factory _$AppPreferencesCopyWith(_AppPreferences value, $Res Function(_AppPreferences) _then) = __$AppPreferencesCopyWithImpl;
@override @useResult
$Res call({
 String summaryProvider, String summaryLength, String themeMode, String localePreference, String transcriptionModel
});




}
/// @nodoc
class __$AppPreferencesCopyWithImpl<$Res>
    implements _$AppPreferencesCopyWith<$Res> {
  __$AppPreferencesCopyWithImpl(this._self, this._then);

  final _AppPreferences _self;
  final $Res Function(_AppPreferences) _then;

/// Create a copy of AppPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summaryProvider = null,Object? summaryLength = null,Object? themeMode = null,Object? localePreference = null,Object? transcriptionModel = null,}) {
  return _then(_AppPreferences(
summaryProvider: null == summaryProvider ? _self.summaryProvider : summaryProvider // ignore: cast_nullable_to_non_nullable
as String,summaryLength: null == summaryLength ? _self.summaryLength : summaryLength // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,localePreference: null == localePreference ? _self.localePreference : localePreference // ignore: cast_nullable_to_non_nullable
as String,transcriptionModel: null == transcriptionModel ? _self.transcriptionModel : transcriptionModel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TranscriptSnapshot {

 List<Transcript> get transcripts; List<TranscriptChunk> get chunks; List<Summary> get summaries; AppPreferences get preferences;
/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscriptSnapshotCopyWith<TranscriptSnapshot> get copyWith => _$TranscriptSnapshotCopyWithImpl<TranscriptSnapshot>(this as TranscriptSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscriptSnapshot&&const DeepCollectionEquality().equals(other.transcripts, transcripts)&&const DeepCollectionEquality().equals(other.chunks, chunks)&&const DeepCollectionEquality().equals(other.summaries, summaries)&&(identical(other.preferences, preferences) || other.preferences == preferences));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(transcripts),const DeepCollectionEquality().hash(chunks),const DeepCollectionEquality().hash(summaries),preferences);

@override
String toString() {
  return 'TranscriptSnapshot(transcripts: $transcripts, chunks: $chunks, summaries: $summaries, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class $TranscriptSnapshotCopyWith<$Res>  {
  factory $TranscriptSnapshotCopyWith(TranscriptSnapshot value, $Res Function(TranscriptSnapshot) _then) = _$TranscriptSnapshotCopyWithImpl;
@useResult
$Res call({
 List<Transcript> transcripts, List<TranscriptChunk> chunks, List<Summary> summaries, AppPreferences preferences
});


$AppPreferencesCopyWith<$Res> get preferences;

}
/// @nodoc
class _$TranscriptSnapshotCopyWithImpl<$Res>
    implements $TranscriptSnapshotCopyWith<$Res> {
  _$TranscriptSnapshotCopyWithImpl(this._self, this._then);

  final TranscriptSnapshot _self;
  final $Res Function(TranscriptSnapshot) _then;

/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transcripts = null,Object? chunks = null,Object? summaries = null,Object? preferences = null,}) {
  return _then(_self.copyWith(
transcripts: null == transcripts ? _self.transcripts : transcripts // ignore: cast_nullable_to_non_nullable
as List<Transcript>,chunks: null == chunks ? _self.chunks : chunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,summaries: null == summaries ? _self.summaries : summaries // ignore: cast_nullable_to_non_nullable
as List<Summary>,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as AppPreferences,
  ));
}
/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppPreferencesCopyWith<$Res> get preferences {
  
  return $AppPreferencesCopyWith<$Res>(_self.preferences, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [TranscriptSnapshot].
extension TranscriptSnapshotPatterns on TranscriptSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscriptSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscriptSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscriptSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TranscriptSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscriptSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TranscriptSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transcript> transcripts,  List<TranscriptChunk> chunks,  List<Summary> summaries,  AppPreferences preferences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranscriptSnapshot() when $default != null:
return $default(_that.transcripts,_that.chunks,_that.summaries,_that.preferences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transcript> transcripts,  List<TranscriptChunk> chunks,  List<Summary> summaries,  AppPreferences preferences)  $default,) {final _that = this;
switch (_that) {
case _TranscriptSnapshot():
return $default(_that.transcripts,_that.chunks,_that.summaries,_that.preferences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transcript> transcripts,  List<TranscriptChunk> chunks,  List<Summary> summaries,  AppPreferences preferences)?  $default,) {final _that = this;
switch (_that) {
case _TranscriptSnapshot() when $default != null:
return $default(_that.transcripts,_that.chunks,_that.summaries,_that.preferences);case _:
  return null;

}
}

}

/// @nodoc


class _TranscriptSnapshot extends TranscriptSnapshot {
  const _TranscriptSnapshot({required final  List<Transcript> transcripts, required final  List<TranscriptChunk> chunks, required final  List<Summary> summaries, this.preferences = const AppPreferences()}): _transcripts = transcripts,_chunks = chunks,_summaries = summaries,super._();
  

 final  List<Transcript> _transcripts;
@override List<Transcript> get transcripts {
  if (_transcripts is EqualUnmodifiableListView) return _transcripts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcripts);
}

 final  List<TranscriptChunk> _chunks;
@override List<TranscriptChunk> get chunks {
  if (_chunks is EqualUnmodifiableListView) return _chunks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chunks);
}

 final  List<Summary> _summaries;
@override List<Summary> get summaries {
  if (_summaries is EqualUnmodifiableListView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_summaries);
}

@override@JsonKey() final  AppPreferences preferences;

/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscriptSnapshotCopyWith<_TranscriptSnapshot> get copyWith => __$TranscriptSnapshotCopyWithImpl<_TranscriptSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscriptSnapshot&&const DeepCollectionEquality().equals(other._transcripts, _transcripts)&&const DeepCollectionEquality().equals(other._chunks, _chunks)&&const DeepCollectionEquality().equals(other._summaries, _summaries)&&(identical(other.preferences, preferences) || other.preferences == preferences));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcripts),const DeepCollectionEquality().hash(_chunks),const DeepCollectionEquality().hash(_summaries),preferences);

@override
String toString() {
  return 'TranscriptSnapshot(transcripts: $transcripts, chunks: $chunks, summaries: $summaries, preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class _$TranscriptSnapshotCopyWith<$Res> implements $TranscriptSnapshotCopyWith<$Res> {
  factory _$TranscriptSnapshotCopyWith(_TranscriptSnapshot value, $Res Function(_TranscriptSnapshot) _then) = __$TranscriptSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<Transcript> transcripts, List<TranscriptChunk> chunks, List<Summary> summaries, AppPreferences preferences
});


@override $AppPreferencesCopyWith<$Res> get preferences;

}
/// @nodoc
class __$TranscriptSnapshotCopyWithImpl<$Res>
    implements _$TranscriptSnapshotCopyWith<$Res> {
  __$TranscriptSnapshotCopyWithImpl(this._self, this._then);

  final _TranscriptSnapshot _self;
  final $Res Function(_TranscriptSnapshot) _then;

/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transcripts = null,Object? chunks = null,Object? summaries = null,Object? preferences = null,}) {
  return _then(_TranscriptSnapshot(
transcripts: null == transcripts ? _self._transcripts : transcripts // ignore: cast_nullable_to_non_nullable
as List<Transcript>,chunks: null == chunks ? _self._chunks : chunks // ignore: cast_nullable_to_non_nullable
as List<TranscriptChunk>,summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as List<Summary>,preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as AppPreferences,
  ));
}

/// Create a copy of TranscriptSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppPreferencesCopyWith<$Res> get preferences {
  
  return $AppPreferencesCopyWith<$Res>(_self.preferences, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}

// dart format on
