// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_pairing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerPairingImpl _$$PlayerPairingImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPairingImpl(
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
      gamesPlayedTogether: (json['gamesPlayedTogether'] as num?)?.toInt() ?? 0,
      gamesWonTogether: (json['gamesWonTogether'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble(),
      lastPlayedTogether: _$JsonConverterFromJson<Object, DateTime>(
          json['lastPlayedTogether'], const TimestampConverter().fromJson),
      pairingId: json['pairingId'] as String?,
    );

Map<String, dynamic> _$$PlayerPairingImplToJson(_$PlayerPairingImpl instance) =>
    <String, dynamic>{
      'player1Id': instance.player1Id,
      'player2Id': instance.player2Id,
      'gamesPlayedTogether': instance.gamesPlayedTogether,
      'gamesWonTogether': instance.gamesWonTogether,
      'winRate': instance.winRate,
      'lastPlayedTogether': _$JsonConverterToJson<Object, DateTime>(
          instance.lastPlayedTogether, const TimestampConverter().toJson),
      'pairingId': instance.pairingId,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
