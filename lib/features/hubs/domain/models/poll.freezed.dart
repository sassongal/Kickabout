// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Poll _$PollFromJson(Map<String, dynamic> json) {
  return _Poll.fromJson(json);
}

/// @nodoc
mixin _$Poll {
  String get pollId => throw _privateConstructorUsedError;
  String get hubId => throw _privateConstructorUsedError;
  String get createdBy =>
      throw _privateConstructorUsedError; // User ID של היוצר
  String get question => throw _privateConstructorUsedError; // השאלה
  List<PollOption> get options =>
      throw _privateConstructorUsedError; // אפשרויות ההצבעה
  PollType get type => throw _privateConstructorUsedError;
  PollStatus get status => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get endsAt =>
      throw _privateConstructorUsedError; // תאריך סיום (null = ללא תאריך סיום)
  @TimestampConverter()
  DateTime? get closedAt => throw _privateConstructorUsedError;
  int get totalVotes => throw _privateConstructorUsedError; // סה"כ הצבעות
  List<String> get voters =>
      throw _privateConstructorUsedError; // רשימת IDs של מי שהצביע (למניעת הצבעות כפולות)
  bool get allowMultipleVotes =>
      throw _privateConstructorUsedError; // האם מותר להצביע יותר מפעם אחת
  bool get showResultsBeforeVote =>
      throw _privateConstructorUsedError; // האם להציג תוצאות לפני הצבעה
  bool get isAnonymous =>
      throw _privateConstructorUsedError; // האם ההצבעה אנונימית
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this Poll to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PollCopyWith<Poll> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollCopyWith<$Res> {
  factory $PollCopyWith(Poll value, $Res Function(Poll) then) =
      _$PollCopyWithImpl<$Res, Poll>;
  @useResult
  $Res call(
      {String pollId,
      String hubId,
      String createdBy,
      String question,
      List<PollOption> options,
      PollType type,
      PollStatus status,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime? endsAt,
      @TimestampConverter() DateTime? closedAt,
      int totalVotes,
      List<String> voters,
      bool allowMultipleVotes,
      bool showResultsBeforeVote,
      bool isAnonymous,
      String? description});
}

/// @nodoc
class _$PollCopyWithImpl<$Res, $Val extends Poll>
    implements $PollCopyWith<$Res> {
  _$PollCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollId = null,
    Object? hubId = null,
    Object? createdBy = null,
    Object? question = null,
    Object? options = null,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endsAt = freezed,
    Object? closedAt = freezed,
    Object? totalVotes = null,
    Object? voters = null,
    Object? allowMultipleVotes = null,
    Object? showResultsBeforeVote = null,
    Object? isAnonymous = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      pollId: null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<PollOption>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PollType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PollStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalVotes: null == totalVotes
          ? _value.totalVotes
          : totalVotes // ignore: cast_nullable_to_non_nullable
              as int,
      voters: null == voters
          ? _value.voters
          : voters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      allowMultipleVotes: null == allowMultipleVotes
          ? _value.allowMultipleVotes
          : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
              as bool,
      showResultsBeforeVote: null == showResultsBeforeVote
          ? _value.showResultsBeforeVote
          : showResultsBeforeVote // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PollImplCopyWith<$Res> implements $PollCopyWith<$Res> {
  factory _$$PollImplCopyWith(
          _$PollImpl value, $Res Function(_$PollImpl) then) =
      __$$PollImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String pollId,
      String hubId,
      String createdBy,
      String question,
      List<PollOption> options,
      PollType type,
      PollStatus status,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime? endsAt,
      @TimestampConverter() DateTime? closedAt,
      int totalVotes,
      List<String> voters,
      bool allowMultipleVotes,
      bool showResultsBeforeVote,
      bool isAnonymous,
      String? description});
}

/// @nodoc
class __$$PollImplCopyWithImpl<$Res>
    extends _$PollCopyWithImpl<$Res, _$PollImpl>
    implements _$$PollImplCopyWith<$Res> {
  __$$PollImplCopyWithImpl(_$PollImpl _value, $Res Function(_$PollImpl) _then)
      : super(_value, _then);

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollId = null,
    Object? hubId = null,
    Object? createdBy = null,
    Object? question = null,
    Object? options = null,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endsAt = freezed,
    Object? closedAt = freezed,
    Object? totalVotes = null,
    Object? voters = null,
    Object? allowMultipleVotes = null,
    Object? showResultsBeforeVote = null,
    Object? isAnonymous = null,
    Object? description = freezed,
  }) {
    return _then(_$PollImpl(
      pollId: null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<PollOption>,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PollType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PollStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalVotes: null == totalVotes
          ? _value.totalVotes
          : totalVotes // ignore: cast_nullable_to_non_nullable
              as int,
      voters: null == voters
          ? _value._voters
          : voters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      allowMultipleVotes: null == allowMultipleVotes
          ? _value.allowMultipleVotes
          : allowMultipleVotes // ignore: cast_nullable_to_non_nullable
              as bool,
      showResultsBeforeVote: null == showResultsBeforeVote
          ? _value.showResultsBeforeVote
          : showResultsBeforeVote // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PollImpl implements _Poll {
  const _$PollImpl(
      {required this.pollId,
      required this.hubId,
      required this.createdBy,
      required this.question,
      required final List<PollOption> options,
      required this.type,
      required this.status,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() this.endsAt,
      @TimestampConverter() this.closedAt,
      this.totalVotes = 0,
      final List<String> voters = const [],
      this.allowMultipleVotes = false,
      this.showResultsBeforeVote = false,
      this.isAnonymous = false,
      this.description})
      : _options = options,
        _voters = voters;

  factory _$PollImpl.fromJson(Map<String, dynamic> json) =>
      _$$PollImplFromJson(json);

  @override
  final String pollId;
  @override
  final String hubId;
  @override
  final String createdBy;
// User ID של היוצר
  @override
  final String question;
// השאלה
  final List<PollOption> _options;
// השאלה
  @override
  List<PollOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

// אפשרויות ההצבעה
  @override
  final PollType type;
  @override
  final PollStatus status;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime? endsAt;
// תאריך סיום (null = ללא תאריך סיום)
  @override
  @TimestampConverter()
  final DateTime? closedAt;
  @override
  @JsonKey()
  final int totalVotes;
// סה"כ הצבעות
  final List<String> _voters;
// סה"כ הצבעות
  @override
  @JsonKey()
  List<String> get voters {
    if (_voters is EqualUnmodifiableListView) return _voters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_voters);
  }

// רשימת IDs של מי שהצביע (למניעת הצבעות כפולות)
  @override
  @JsonKey()
  final bool allowMultipleVotes;
// האם מותר להצביע יותר מפעם אחת
  @override
  @JsonKey()
  final bool showResultsBeforeVote;
// האם להציג תוצאות לפני הצבעה
  @override
  @JsonKey()
  final bool isAnonymous;
// האם ההצבעה אנונימית
  @override
  final String? description;

  @override
  String toString() {
    return 'Poll(pollId: $pollId, hubId: $hubId, createdBy: $createdBy, question: $question, options: $options, type: $type, status: $status, createdAt: $createdAt, endsAt: $endsAt, closedAt: $closedAt, totalVotes: $totalVotes, voters: $voters, allowMultipleVotes: $allowMultipleVotes, showResultsBeforeVote: $showResultsBeforeVote, isAnonymous: $isAnonymous, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollImpl &&
            (identical(other.pollId, pollId) || other.pollId == pollId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.question, question) ||
                other.question == question) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt) &&
            (identical(other.totalVotes, totalVotes) ||
                other.totalVotes == totalVotes) &&
            const DeepCollectionEquality().equals(other._voters, _voters) &&
            (identical(other.allowMultipleVotes, allowMultipleVotes) ||
                other.allowMultipleVotes == allowMultipleVotes) &&
            (identical(other.showResultsBeforeVote, showResultsBeforeVote) ||
                other.showResultsBeforeVote == showResultsBeforeVote) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      pollId,
      hubId,
      createdBy,
      question,
      const DeepCollectionEquality().hash(_options),
      type,
      status,
      createdAt,
      endsAt,
      closedAt,
      totalVotes,
      const DeepCollectionEquality().hash(_voters),
      allowMultipleVotes,
      showResultsBeforeVote,
      isAnonymous,
      description);

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollImplCopyWith<_$PollImpl> get copyWith =>
      __$$PollImplCopyWithImpl<_$PollImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PollImplToJson(
      this,
    );
  }
}

abstract class _Poll implements Poll {
  const factory _Poll(
      {required final String pollId,
      required final String hubId,
      required final String createdBy,
      required final String question,
      required final List<PollOption> options,
      required final PollType type,
      required final PollStatus status,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() final DateTime? endsAt,
      @TimestampConverter() final DateTime? closedAt,
      final int totalVotes,
      final List<String> voters,
      final bool allowMultipleVotes,
      final bool showResultsBeforeVote,
      final bool isAnonymous,
      final String? description}) = _$PollImpl;

  factory _Poll.fromJson(Map<String, dynamic> json) = _$PollImpl.fromJson;

  @override
  String get pollId;
  @override
  String get hubId;
  @override
  String get createdBy; // User ID של היוצר
  @override
  String get question; // השאלה
  @override
  List<PollOption> get options; // אפשרויות ההצבעה
  @override
  PollType get type;
  @override
  PollStatus get status;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime? get endsAt; // תאריך סיום (null = ללא תאריך סיום)
  @override
  @TimestampConverter()
  DateTime? get closedAt;
  @override
  int get totalVotes; // סה"כ הצבעות
  @override
  List<String> get voters; // רשימת IDs של מי שהצביע (למניעת הצבעות כפולות)
  @override
  bool get allowMultipleVotes; // האם מותר להצביע יותר מפעם אחת
  @override
  bool get showResultsBeforeVote; // האם להציג תוצאות לפני הצבעה
  @override
  bool get isAnonymous; // האם ההצבעה אנונימית
  @override
  String? get description;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollImplCopyWith<_$PollImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PollOption _$PollOptionFromJson(Map<String, dynamic> json) {
  return _PollOption.fromJson(json);
}

/// @nodoc
mixin _$PollOption {
  String get optionId => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  int get voteCount => throw _privateConstructorUsedError;
  List<String> get voters =>
      throw _privateConstructorUsedError; // מי הצביע לאפשרות הזו (אם לא אנונימי)
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this PollOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PollOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PollOptionCopyWith<PollOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollOptionCopyWith<$Res> {
  factory $PollOptionCopyWith(
          PollOption value, $Res Function(PollOption) then) =
      _$PollOptionCopyWithImpl<$Res, PollOption>;
  @useResult
  $Res call(
      {String optionId,
      String text,
      int voteCount,
      List<String> voters,
      String? imageUrl});
}

/// @nodoc
class _$PollOptionCopyWithImpl<$Res, $Val extends PollOption>
    implements $PollOptionCopyWith<$Res> {
  _$PollOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PollOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? optionId = null,
    Object? text = null,
    Object? voteCount = null,
    Object? voters = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_value.copyWith(
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
      voters: null == voters
          ? _value.voters
          : voters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PollOptionImplCopyWith<$Res>
    implements $PollOptionCopyWith<$Res> {
  factory _$$PollOptionImplCopyWith(
          _$PollOptionImpl value, $Res Function(_$PollOptionImpl) then) =
      __$$PollOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String optionId,
      String text,
      int voteCount,
      List<String> voters,
      String? imageUrl});
}

/// @nodoc
class __$$PollOptionImplCopyWithImpl<$Res>
    extends _$PollOptionCopyWithImpl<$Res, _$PollOptionImpl>
    implements _$$PollOptionImplCopyWith<$Res> {
  __$$PollOptionImplCopyWithImpl(
      _$PollOptionImpl _value, $Res Function(_$PollOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PollOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? optionId = null,
    Object? text = null,
    Object? voteCount = null,
    Object? voters = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_$PollOptionImpl(
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
      voters: null == voters
          ? _value._voters
          : voters // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PollOptionImpl implements _PollOption {
  const _$PollOptionImpl(
      {required this.optionId,
      required this.text,
      this.voteCount = 0,
      final List<String> voters = const [],
      this.imageUrl})
      : _voters = voters;

  factory _$PollOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PollOptionImplFromJson(json);

  @override
  final String optionId;
  @override
  final String text;
  @override
  @JsonKey()
  final int voteCount;
  final List<String> _voters;
  @override
  @JsonKey()
  List<String> get voters {
    if (_voters is EqualUnmodifiableListView) return _voters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_voters);
  }

// מי הצביע לאפשרות הזו (אם לא אנונימי)
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'PollOption(optionId: $optionId, text: $text, voteCount: $voteCount, voters: $voters, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollOptionImpl &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.voteCount, voteCount) ||
                other.voteCount == voteCount) &&
            const DeepCollectionEquality().equals(other._voters, _voters) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, optionId, text, voteCount,
      const DeepCollectionEquality().hash(_voters), imageUrl);

  /// Create a copy of PollOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollOptionImplCopyWith<_$PollOptionImpl> get copyWith =>
      __$$PollOptionImplCopyWithImpl<_$PollOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PollOptionImplToJson(
      this,
    );
  }
}

abstract class _PollOption implements PollOption {
  const factory _PollOption(
      {required final String optionId,
      required final String text,
      final int voteCount,
      final List<String> voters,
      final String? imageUrl}) = _$PollOptionImpl;

  factory _PollOption.fromJson(Map<String, dynamic> json) =
      _$PollOptionImpl.fromJson;

  @override
  String get optionId;
  @override
  String get text;
  @override
  int get voteCount;
  @override
  List<String> get voters; // מי הצביע לאפשרות הזו (אם לא אנונימי)
  @override
  String? get imageUrl;

  /// Create a copy of PollOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollOptionImplCopyWith<_$PollOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PollVote _$PollVoteFromJson(Map<String, dynamic> json) {
  return _PollVote.fromJson(json);
}

/// @nodoc
mixin _$PollVote {
  String get voteId => throw _privateConstructorUsedError;
  String get pollId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  List<String> get selectedOptionIds =>
      throw _privateConstructorUsedError; // יכול להיות יותר מאחד ב-multipleChoice
  @TimestampConverter()
  DateTime get votedAt => throw _privateConstructorUsedError;
  int? get rating => throw _privateConstructorUsedError;

  /// Serializes this PollVote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PollVote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PollVoteCopyWith<PollVote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollVoteCopyWith<$Res> {
  factory $PollVoteCopyWith(PollVote value, $Res Function(PollVote) then) =
      _$PollVoteCopyWithImpl<$Res, PollVote>;
  @useResult
  $Res call(
      {String voteId,
      String pollId,
      String userId,
      List<String> selectedOptionIds,
      @TimestampConverter() DateTime votedAt,
      int? rating});
}

/// @nodoc
class _$PollVoteCopyWithImpl<$Res, $Val extends PollVote>
    implements $PollVoteCopyWith<$Res> {
  _$PollVoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PollVote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voteId = null,
    Object? pollId = null,
    Object? userId = null,
    Object? selectedOptionIds = null,
    Object? votedAt = null,
    Object? rating = freezed,
  }) {
    return _then(_value.copyWith(
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as String,
      pollId: null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedOptionIds: null == selectedOptionIds
          ? _value.selectedOptionIds
          : selectedOptionIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      votedAt: null == votedAt
          ? _value.votedAt
          : votedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PollVoteImplCopyWith<$Res>
    implements $PollVoteCopyWith<$Res> {
  factory _$$PollVoteImplCopyWith(
          _$PollVoteImpl value, $Res Function(_$PollVoteImpl) then) =
      __$$PollVoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String voteId,
      String pollId,
      String userId,
      List<String> selectedOptionIds,
      @TimestampConverter() DateTime votedAt,
      int? rating});
}

/// @nodoc
class __$$PollVoteImplCopyWithImpl<$Res>
    extends _$PollVoteCopyWithImpl<$Res, _$PollVoteImpl>
    implements _$$PollVoteImplCopyWith<$Res> {
  __$$PollVoteImplCopyWithImpl(
      _$PollVoteImpl _value, $Res Function(_$PollVoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of PollVote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voteId = null,
    Object? pollId = null,
    Object? userId = null,
    Object? selectedOptionIds = null,
    Object? votedAt = null,
    Object? rating = freezed,
  }) {
    return _then(_$PollVoteImpl(
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as String,
      pollId: null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      selectedOptionIds: null == selectedOptionIds
          ? _value._selectedOptionIds
          : selectedOptionIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      votedAt: null == votedAt
          ? _value.votedAt
          : votedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PollVoteImpl implements _PollVote {
  const _$PollVoteImpl(
      {required this.voteId,
      required this.pollId,
      required this.userId,
      required final List<String> selectedOptionIds,
      @TimestampConverter() required this.votedAt,
      this.rating})
      : _selectedOptionIds = selectedOptionIds;

  factory _$PollVoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$PollVoteImplFromJson(json);

  @override
  final String voteId;
  @override
  final String pollId;
  @override
  final String userId;
  final List<String> _selectedOptionIds;
  @override
  List<String> get selectedOptionIds {
    if (_selectedOptionIds is EqualUnmodifiableListView)
      return _selectedOptionIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedOptionIds);
  }

// יכול להיות יותר מאחד ב-multipleChoice
  @override
  @TimestampConverter()
  final DateTime votedAt;
  @override
  final int? rating;

  @override
  String toString() {
    return 'PollVote(voteId: $voteId, pollId: $pollId, userId: $userId, selectedOptionIds: $selectedOptionIds, votedAt: $votedAt, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollVoteImpl &&
            (identical(other.voteId, voteId) || other.voteId == voteId) &&
            (identical(other.pollId, pollId) || other.pollId == pollId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality()
                .equals(other._selectedOptionIds, _selectedOptionIds) &&
            (identical(other.votedAt, votedAt) || other.votedAt == votedAt) &&
            (identical(other.rating, rating) || other.rating == rating));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, voteId, pollId, userId,
      const DeepCollectionEquality().hash(_selectedOptionIds), votedAt, rating);

  /// Create a copy of PollVote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollVoteImplCopyWith<_$PollVoteImpl> get copyWith =>
      __$$PollVoteImplCopyWithImpl<_$PollVoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PollVoteImplToJson(
      this,
    );
  }
}

abstract class _PollVote implements PollVote {
  const factory _PollVote(
      {required final String voteId,
      required final String pollId,
      required final String userId,
      required final List<String> selectedOptionIds,
      @TimestampConverter() required final DateTime votedAt,
      final int? rating}) = _$PollVoteImpl;

  factory _PollVote.fromJson(Map<String, dynamic> json) =
      _$PollVoteImpl.fromJson;

  @override
  String get voteId;
  @override
  String get pollId;
  @override
  String get userId;
  @override
  List<String> get selectedOptionIds; // יכול להיות יותר מאחד ב-multipleChoice
  @override
  @TimestampConverter()
  DateTime get votedAt;
  @override
  int? get rating;

  /// Create a copy of PollVote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollVoteImplCopyWith<_$PollVoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
