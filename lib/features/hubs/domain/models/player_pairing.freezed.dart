// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_pairing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerPairing _$PlayerPairingFromJson(Map<String, dynamic> json) {
  return _PlayerPairing.fromJson(json);
}

/// @nodoc
mixin _$PlayerPairing {
  /// ID of first player (alphabetically first)
  String get player1Id => throw _privateConstructorUsedError;

  /// ID of second player (alphabetically second)
  String get player2Id => throw _privateConstructorUsedError;

  /// Total number of games played together on the same team
  int get gamesPlayedTogether => throw _privateConstructorUsedError;

  /// Number of games won together on the same team
  int get gamesWonTogether => throw _privateConstructorUsedError;

  /// Win rate (0.0-1.0) calculated as gamesWonTogether / gamesPlayedTogether
  /// Null if gamesPlayedTogether == 0
  double? get winRate => throw _privateConstructorUsedError;

  /// Timestamp of last game played together
  @TimestampConverter()
  DateTime? get lastPlayedTogether => throw _privateConstructorUsedError;

  /// Auto-calculated pairing ID (player1Id_player2Id)
  String? get pairingId => throw _privateConstructorUsedError;

  /// Serializes this PlayerPairing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerPairing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerPairingCopyWith<PlayerPairing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerPairingCopyWith<$Res> {
  factory $PlayerPairingCopyWith(
          PlayerPairing value, $Res Function(PlayerPairing) then) =
      _$PlayerPairingCopyWithImpl<$Res, PlayerPairing>;
  @useResult
  $Res call(
      {String player1Id,
      String player2Id,
      int gamesPlayedTogether,
      int gamesWonTogether,
      double? winRate,
      @TimestampConverter() DateTime? lastPlayedTogether,
      String? pairingId});
}

/// @nodoc
class _$PlayerPairingCopyWithImpl<$Res, $Val extends PlayerPairing>
    implements $PlayerPairingCopyWith<$Res> {
  _$PlayerPairingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerPairing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? player1Id = null,
    Object? player2Id = null,
    Object? gamesPlayedTogether = null,
    Object? gamesWonTogether = null,
    Object? winRate = freezed,
    Object? lastPlayedTogether = freezed,
    Object? pairingId = freezed,
  }) {
    return _then(_value.copyWith(
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: null == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String,
      gamesPlayedTogether: null == gamesPlayedTogether
          ? _value.gamesPlayedTogether
          : gamesPlayedTogether // ignore: cast_nullable_to_non_nullable
              as int,
      gamesWonTogether: null == gamesWonTogether
          ? _value.gamesWonTogether
          : gamesWonTogether // ignore: cast_nullable_to_non_nullable
              as int,
      winRate: freezed == winRate
          ? _value.winRate
          : winRate // ignore: cast_nullable_to_non_nullable
              as double?,
      lastPlayedTogether: freezed == lastPlayedTogether
          ? _value.lastPlayedTogether
          : lastPlayedTogether // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pairingId: freezed == pairingId
          ? _value.pairingId
          : pairingId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerPairingImplCopyWith<$Res>
    implements $PlayerPairingCopyWith<$Res> {
  factory _$$PlayerPairingImplCopyWith(
          _$PlayerPairingImpl value, $Res Function(_$PlayerPairingImpl) then) =
      __$$PlayerPairingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String player1Id,
      String player2Id,
      int gamesPlayedTogether,
      int gamesWonTogether,
      double? winRate,
      @TimestampConverter() DateTime? lastPlayedTogether,
      String? pairingId});
}

/// @nodoc
class __$$PlayerPairingImplCopyWithImpl<$Res>
    extends _$PlayerPairingCopyWithImpl<$Res, _$PlayerPairingImpl>
    implements _$$PlayerPairingImplCopyWith<$Res> {
  __$$PlayerPairingImplCopyWithImpl(
      _$PlayerPairingImpl _value, $Res Function(_$PlayerPairingImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerPairing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? player1Id = null,
    Object? player2Id = null,
    Object? gamesPlayedTogether = null,
    Object? gamesWonTogether = null,
    Object? winRate = freezed,
    Object? lastPlayedTogether = freezed,
    Object? pairingId = freezed,
  }) {
    return _then(_$PlayerPairingImpl(
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: null == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String,
      gamesPlayedTogether: null == gamesPlayedTogether
          ? _value.gamesPlayedTogether
          : gamesPlayedTogether // ignore: cast_nullable_to_non_nullable
              as int,
      gamesWonTogether: null == gamesWonTogether
          ? _value.gamesWonTogether
          : gamesWonTogether // ignore: cast_nullable_to_non_nullable
              as int,
      winRate: freezed == winRate
          ? _value.winRate
          : winRate // ignore: cast_nullable_to_non_nullable
              as double?,
      lastPlayedTogether: freezed == lastPlayedTogether
          ? _value.lastPlayedTogether
          : lastPlayedTogether // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      pairingId: freezed == pairingId
          ? _value.pairingId
          : pairingId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerPairingImpl implements _PlayerPairing {
  const _$PlayerPairingImpl(
      {required this.player1Id,
      required this.player2Id,
      this.gamesPlayedTogether = 0,
      this.gamesWonTogether = 0,
      this.winRate,
      @TimestampConverter() this.lastPlayedTogether,
      this.pairingId});

  factory _$PlayerPairingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPairingImplFromJson(json);

  /// ID of first player (alphabetically first)
  @override
  final String player1Id;

  /// ID of second player (alphabetically second)
  @override
  final String player2Id;

  /// Total number of games played together on the same team
  @override
  @JsonKey()
  final int gamesPlayedTogether;

  /// Number of games won together on the same team
  @override
  @JsonKey()
  final int gamesWonTogether;

  /// Win rate (0.0-1.0) calculated as gamesWonTogether / gamesPlayedTogether
  /// Null if gamesPlayedTogether == 0
  @override
  final double? winRate;

  /// Timestamp of last game played together
  @override
  @TimestampConverter()
  final DateTime? lastPlayedTogether;

  /// Auto-calculated pairing ID (player1Id_player2Id)
  @override
  final String? pairingId;

  @override
  String toString() {
    return 'PlayerPairing(player1Id: $player1Id, player2Id: $player2Id, gamesPlayedTogether: $gamesPlayedTogether, gamesWonTogether: $gamesWonTogether, winRate: $winRate, lastPlayedTogether: $lastPlayedTogether, pairingId: $pairingId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPairingImpl &&
            (identical(other.player1Id, player1Id) ||
                other.player1Id == player1Id) &&
            (identical(other.player2Id, player2Id) ||
                other.player2Id == player2Id) &&
            (identical(other.gamesPlayedTogether, gamesPlayedTogether) ||
                other.gamesPlayedTogether == gamesPlayedTogether) &&
            (identical(other.gamesWonTogether, gamesWonTogether) ||
                other.gamesWonTogether == gamesWonTogether) &&
            (identical(other.winRate, winRate) || other.winRate == winRate) &&
            (identical(other.lastPlayedTogether, lastPlayedTogether) ||
                other.lastPlayedTogether == lastPlayedTogether) &&
            (identical(other.pairingId, pairingId) ||
                other.pairingId == pairingId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      player1Id,
      player2Id,
      gamesPlayedTogether,
      gamesWonTogether,
      winRate,
      lastPlayedTogether,
      pairingId);

  /// Create a copy of PlayerPairing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerPairingImplCopyWith<_$PlayerPairingImpl> get copyWith =>
      __$$PlayerPairingImplCopyWithImpl<_$PlayerPairingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerPairingImplToJson(
      this,
    );
  }
}

abstract class _PlayerPairing implements PlayerPairing {
  const factory _PlayerPairing(
      {required final String player1Id,
      required final String player2Id,
      final int gamesPlayedTogether,
      final int gamesWonTogether,
      final double? winRate,
      @TimestampConverter() final DateTime? lastPlayedTogether,
      final String? pairingId}) = _$PlayerPairingImpl;

  factory _PlayerPairing.fromJson(Map<String, dynamic> json) =
      _$PlayerPairingImpl.fromJson;

  /// ID of first player (alphabetically first)
  @override
  String get player1Id;

  /// ID of second player (alphabetically second)
  @override
  String get player2Id;

  /// Total number of games played together on the same team
  @override
  int get gamesPlayedTogether;

  /// Number of games won together on the same team
  @override
  int get gamesWonTogether;

  /// Win rate (0.0-1.0) calculated as gamesWonTogether / gamesPlayedTogether
  /// Null if gamesPlayedTogether == 0
  @override
  double? get winRate;

  /// Timestamp of last game played together
  @override
  @TimestampConverter()
  DateTime? get lastPlayedTogether;

  /// Auto-calculated pairing ID (player1Id_player2Id)
  @override
  String? get pairingId;

  /// Create a copy of PlayerPairing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerPairingImplCopyWith<_$PlayerPairingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
