// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeedPost _$FeedPostFromJson(Map<String, dynamic> json) {
  return _FeedPost.fromJson(json);
}

/// @nodoc
mixin _$FeedPost {
  String get postId => throw _privateConstructorUsedError;
  String get hubId => throw _privateConstructorUsedError;
  String get authorId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'game' | 'achievement' | 'rating' | 'post' | 'game_created' | 'hub_recruiting'
  String? get content => throw _privateConstructorUsedError;
  String? get text =>
      throw _privateConstructorUsedError; // Alternative to content (used by onGameCreated)
  String? get gameId => throw _privateConstructorUsedError;
  String? get eventId =>
      throw _privateConstructorUsedError; // For recruiting posts linked to events
  String? get achievementId =>
      throw _privateConstructorUsedError; // Recruiting post fields
  bool get isUrgent => throw _privateConstructorUsedError; // Show "דחוף" badge
  @NullableTimestampConverter()
  DateTime? get recruitingUntil =>
      throw _privateConstructorUsedError; // Deadline for recruiting
  int get neededPlayers =>
      throw _privateConstructorUsedError; // How many players needed
  List<String> get likes => throw _privateConstructorUsedError;
  int get likeCount =>
      throw _privateConstructorUsedError; // Denormalized count for sorting
  int get commentCount =>
      throw _privateConstructorUsedError; // Denormalized: Count of comments (Cloud Function writes this)
// Note: commentsCount is kept for backward compatibility. Prefer using commentCount.
  int get commentsCount =>
      throw _privateConstructorUsedError; // Legacy alias - maps to commentCount in Firestore
  List<String> get comments =>
      throw _privateConstructorUsedError; // Legacy: Array of comment IDs (deprecated, use subcollection)
  List<String> get photoUrls =>
      throw _privateConstructorUsedError; // URLs of photos/videos in the post
  @TimestampConverter()
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Denormalized fields for efficient display (no need to fetch hub/user)
  String? get hubName =>
      throw _privateConstructorUsedError; // Denormalized from hubs/{hubId}.name
  String? get hubLogoUrl =>
      throw _privateConstructorUsedError; // Denormalized from hubs/{hubId}.logoUrl
  String? get authorName =>
      throw _privateConstructorUsedError; // Denormalized from users/{authorId}.name
  String? get authorPhotoUrl =>
      throw _privateConstructorUsedError; // Denormalized from users/{authorId}.photoUrl
  String? get entityId =>
      throw _privateConstructorUsedError; // ID of related entity (gameId, etc.)
  String? get region => throw _privateConstructorUsedError;

  /// Serializes this FeedPost to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedPostCopyWith<FeedPost> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedPostCopyWith<$Res> {
  factory $FeedPostCopyWith(FeedPost value, $Res Function(FeedPost) then) =
      _$FeedPostCopyWithImpl<$Res, FeedPost>;
  @useResult
  $Res call(
      {String postId,
      String hubId,
      String authorId,
      String type,
      String? content,
      String? text,
      String? gameId,
      String? eventId,
      String? achievementId,
      bool isUrgent,
      @NullableTimestampConverter() DateTime? recruitingUntil,
      int neededPlayers,
      List<String> likes,
      int likeCount,
      int commentCount,
      int commentsCount,
      List<String> comments,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      String? hubName,
      String? hubLogoUrl,
      String? authorName,
      String? authorPhotoUrl,
      String? entityId,
      String? region});
}

/// @nodoc
class _$FeedPostCopyWithImpl<$Res, $Val extends FeedPost>
    implements $FeedPostCopyWith<$Res> {
  _$FeedPostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? hubId = null,
    Object? authorId = null,
    Object? type = null,
    Object? content = freezed,
    Object? text = freezed,
    Object? gameId = freezed,
    Object? eventId = freezed,
    Object? achievementId = freezed,
    Object? isUrgent = null,
    Object? recruitingUntil = freezed,
    Object? neededPlayers = null,
    Object? likes = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? commentsCount = null,
    Object? comments = null,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? hubName = freezed,
    Object? hubLogoUrl = freezed,
    Object? authorName = freezed,
    Object? authorPhotoUrl = freezed,
    Object? entityId = freezed,
    Object? region = freezed,
  }) {
    return _then(_value.copyWith(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      gameId: freezed == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      achievementId: freezed == achievementId
          ? _value.achievementId
          : achievementId // ignore: cast_nullable_to_non_nullable
              as String?,
      isUrgent: null == isUrgent
          ? _value.isUrgent
          : isUrgent // ignore: cast_nullable_to_non_nullable
              as bool,
      recruitingUntil: freezed == recruitingUntil
          ? _value.recruitingUntil
          : recruitingUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      neededPlayers: null == neededPlayers
          ? _value.neededPlayers
          : neededPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      likes: null == likes
          ? _value.likes
          : likes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      hubLogoUrl: freezed == hubLogoUrl
          ? _value.hubLogoUrl
          : hubLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorPhotoUrl: freezed == authorPhotoUrl
          ? _value.authorPhotoUrl
          : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedPostImplCopyWith<$Res>
    implements $FeedPostCopyWith<$Res> {
  factory _$$FeedPostImplCopyWith(
          _$FeedPostImpl value, $Res Function(_$FeedPostImpl) then) =
      __$$FeedPostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String postId,
      String hubId,
      String authorId,
      String type,
      String? content,
      String? text,
      String? gameId,
      String? eventId,
      String? achievementId,
      bool isUrgent,
      @NullableTimestampConverter() DateTime? recruitingUntil,
      int neededPlayers,
      List<String> likes,
      int likeCount,
      int commentCount,
      int commentsCount,
      List<String> comments,
      List<String> photoUrls,
      @TimestampConverter() DateTime createdAt,
      String? hubName,
      String? hubLogoUrl,
      String? authorName,
      String? authorPhotoUrl,
      String? entityId,
      String? region});
}

/// @nodoc
class __$$FeedPostImplCopyWithImpl<$Res>
    extends _$FeedPostCopyWithImpl<$Res, _$FeedPostImpl>
    implements _$$FeedPostImplCopyWith<$Res> {
  __$$FeedPostImplCopyWithImpl(
      _$FeedPostImpl _value, $Res Function(_$FeedPostImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeedPost
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? hubId = null,
    Object? authorId = null,
    Object? type = null,
    Object? content = freezed,
    Object? text = freezed,
    Object? gameId = freezed,
    Object? eventId = freezed,
    Object? achievementId = freezed,
    Object? isUrgent = null,
    Object? recruitingUntil = freezed,
    Object? neededPlayers = null,
    Object? likes = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? commentsCount = null,
    Object? comments = null,
    Object? photoUrls = null,
    Object? createdAt = null,
    Object? hubName = freezed,
    Object? hubLogoUrl = freezed,
    Object? authorName = freezed,
    Object? authorPhotoUrl = freezed,
    Object? entityId = freezed,
    Object? region = freezed,
  }) {
    return _then(_$FeedPostImpl(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      gameId: freezed == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventId: freezed == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String?,
      achievementId: freezed == achievementId
          ? _value.achievementId
          : achievementId // ignore: cast_nullable_to_non_nullable
              as String?,
      isUrgent: null == isUrgent
          ? _value.isUrgent
          : isUrgent // ignore: cast_nullable_to_non_nullable
              as bool,
      recruitingUntil: freezed == recruitingUntil
          ? _value.recruitingUntil
          : recruitingUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      neededPlayers: null == neededPlayers
          ? _value.neededPlayers
          : neededPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      likes: null == likes
          ? _value._likes
          : likes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      likeCount: null == likeCount
          ? _value.likeCount
          : likeCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      comments: null == comments
          ? _value._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      hubLogoUrl: freezed == hubLogoUrl
          ? _value.hubLogoUrl
          : hubLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorPhotoUrl: freezed == authorPhotoUrl
          ? _value.authorPhotoUrl
          : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedPostImpl implements _FeedPost {
  const _$FeedPostImpl(
      {required this.postId,
      required this.hubId,
      required this.authorId,
      required this.type,
      this.content,
      this.text,
      this.gameId,
      this.eventId,
      this.achievementId,
      this.isUrgent = false,
      @NullableTimestampConverter() this.recruitingUntil,
      this.neededPlayers = 0,
      final List<String> likes = const [],
      this.likeCount = 0,
      this.commentCount = 0,
      this.commentsCount = 0,
      final List<String> comments = const [],
      final List<String> photoUrls = const [],
      @TimestampConverter() required this.createdAt,
      this.hubName,
      this.hubLogoUrl,
      this.authorName,
      this.authorPhotoUrl,
      this.entityId,
      this.region})
      : _likes = likes,
        _comments = comments,
        _photoUrls = photoUrls;

  factory _$FeedPostImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedPostImplFromJson(json);

  @override
  final String postId;
  @override
  final String hubId;
  @override
  final String authorId;
  @override
  final String type;
// 'game' | 'achievement' | 'rating' | 'post' | 'game_created' | 'hub_recruiting'
  @override
  final String? content;
  @override
  final String? text;
// Alternative to content (used by onGameCreated)
  @override
  final String? gameId;
  @override
  final String? eventId;
// For recruiting posts linked to events
  @override
  final String? achievementId;
// Recruiting post fields
  @override
  @JsonKey()
  final bool isUrgent;
// Show "דחוף" badge
  @override
  @NullableTimestampConverter()
  final DateTime? recruitingUntil;
// Deadline for recruiting
  @override
  @JsonKey()
  final int neededPlayers;
// How many players needed
  final List<String> _likes;
// How many players needed
  @override
  @JsonKey()
  List<String> get likes {
    if (_likes is EqualUnmodifiableListView) return _likes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_likes);
  }

  @override
  @JsonKey()
  final int likeCount;
// Denormalized count for sorting
  @override
  @JsonKey()
  final int commentCount;
// Denormalized: Count of comments (Cloud Function writes this)
// Note: commentsCount is kept for backward compatibility. Prefer using commentCount.
  @override
  @JsonKey()
  final int commentsCount;
// Legacy alias - maps to commentCount in Firestore
  final List<String> _comments;
// Legacy alias - maps to commentCount in Firestore
  @override
  @JsonKey()
  List<String> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

// Legacy: Array of comment IDs (deprecated, use subcollection)
  final List<String> _photoUrls;
// Legacy: Array of comment IDs (deprecated, use subcollection)
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

// URLs of photos/videos in the post
  @override
  @TimestampConverter()
  final DateTime createdAt;
// Denormalized fields for efficient display (no need to fetch hub/user)
  @override
  final String? hubName;
// Denormalized from hubs/{hubId}.name
  @override
  final String? hubLogoUrl;
// Denormalized from hubs/{hubId}.logoUrl
  @override
  final String? authorName;
// Denormalized from users/{authorId}.name
  @override
  final String? authorPhotoUrl;
// Denormalized from users/{authorId}.photoUrl
  @override
  final String? entityId;
// ID of related entity (gameId, etc.)
  @override
  final String? region;

  @override
  String toString() {
    return 'FeedPost(postId: $postId, hubId: $hubId, authorId: $authorId, type: $type, content: $content, text: $text, gameId: $gameId, eventId: $eventId, achievementId: $achievementId, isUrgent: $isUrgent, recruitingUntil: $recruitingUntil, neededPlayers: $neededPlayers, likes: $likes, likeCount: $likeCount, commentCount: $commentCount, commentsCount: $commentsCount, comments: $comments, photoUrls: $photoUrls, createdAt: $createdAt, hubName: $hubName, hubLogoUrl: $hubLogoUrl, authorName: $authorName, authorPhotoUrl: $authorPhotoUrl, entityId: $entityId, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedPostImpl &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.achievementId, achievementId) ||
                other.achievementId == achievementId) &&
            (identical(other.isUrgent, isUrgent) ||
                other.isUrgent == isUrgent) &&
            (identical(other.recruitingUntil, recruitingUntil) ||
                other.recruitingUntil == recruitingUntil) &&
            (identical(other.neededPlayers, neededPlayers) ||
                other.neededPlayers == neededPlayers) &&
            const DeepCollectionEquality().equals(other._likes, _likes) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            const DeepCollectionEquality().equals(other._comments, _comments) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.hubName, hubName) || other.hubName == hubName) &&
            (identical(other.hubLogoUrl, hubLogoUrl) ||
                other.hubLogoUrl == hubLogoUrl) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorPhotoUrl, authorPhotoUrl) ||
                other.authorPhotoUrl == authorPhotoUrl) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.region, region) || other.region == region));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        postId,
        hubId,
        authorId,
        type,
        content,
        text,
        gameId,
        eventId,
        achievementId,
        isUrgent,
        recruitingUntil,
        neededPlayers,
        const DeepCollectionEquality().hash(_likes),
        likeCount,
        commentCount,
        commentsCount,
        const DeepCollectionEquality().hash(_comments),
        const DeepCollectionEquality().hash(_photoUrls),
        createdAt,
        hubName,
        hubLogoUrl,
        authorName,
        authorPhotoUrl,
        entityId,
        region
      ]);

  /// Create a copy of FeedPost
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedPostImplCopyWith<_$FeedPostImpl> get copyWith =>
      __$$FeedPostImplCopyWithImpl<_$FeedPostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedPostImplToJson(
      this,
    );
  }
}

abstract class _FeedPost implements FeedPost {
  const factory _FeedPost(
      {required final String postId,
      required final String hubId,
      required final String authorId,
      required final String type,
      final String? content,
      final String? text,
      final String? gameId,
      final String? eventId,
      final String? achievementId,
      final bool isUrgent,
      @NullableTimestampConverter() final DateTime? recruitingUntil,
      final int neededPlayers,
      final List<String> likes,
      final int likeCount,
      final int commentCount,
      final int commentsCount,
      final List<String> comments,
      final List<String> photoUrls,
      @TimestampConverter() required final DateTime createdAt,
      final String? hubName,
      final String? hubLogoUrl,
      final String? authorName,
      final String? authorPhotoUrl,
      final String? entityId,
      final String? region}) = _$FeedPostImpl;

  factory _FeedPost.fromJson(Map<String, dynamic> json) =
      _$FeedPostImpl.fromJson;

  @override
  String get postId;
  @override
  String get hubId;
  @override
  String get authorId;
  @override
  String
      get type; // 'game' | 'achievement' | 'rating' | 'post' | 'game_created' | 'hub_recruiting'
  @override
  String? get content;
  @override
  String? get text; // Alternative to content (used by onGameCreated)
  @override
  String? get gameId;
  @override
  String? get eventId; // For recruiting posts linked to events
  @override
  String? get achievementId; // Recruiting post fields
  @override
  bool get isUrgent; // Show "דחוף" badge
  @override
  @NullableTimestampConverter()
  DateTime? get recruitingUntil; // Deadline for recruiting
  @override
  int get neededPlayers; // How many players needed
  @override
  List<String> get likes;
  @override
  int get likeCount; // Denormalized count for sorting
  @override
  int get commentCount; // Denormalized: Count of comments (Cloud Function writes this)
// Note: commentsCount is kept for backward compatibility. Prefer using commentCount.
  @override
  int get commentsCount; // Legacy alias - maps to commentCount in Firestore
  @override
  List<String>
      get comments; // Legacy: Array of comment IDs (deprecated, use subcollection)
  @override
  List<String> get photoUrls; // URLs of photos/videos in the post
  @override
  @TimestampConverter()
  DateTime
      get createdAt; // Denormalized fields for efficient display (no need to fetch hub/user)
  @override
  String? get hubName; // Denormalized from hubs/{hubId}.name
  @override
  String? get hubLogoUrl; // Denormalized from hubs/{hubId}.logoUrl
  @override
  String? get authorName; // Denormalized from users/{authorId}.name
  @override
  String? get authorPhotoUrl; // Denormalized from users/{authorId}.photoUrl
  @override
  String? get entityId; // ID of related entity (gameId, etc.)
  @override
  String? get region;

  /// Create a copy of FeedPost
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedPostImplCopyWith<_$FeedPostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
