import 'package:freezed_annotation/freezed_annotation.dart';

part 'targeting_criteria.freezed.dart';
part 'targeting_criteria.g.dart';

/// Enums for targeting criteria
enum PlayerGender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('any')
  any,
}

enum GameVibe {
  @JsonValue('competitive')
  competitive,
  @JsonValue('casual')
  casual,
}

/// Strict typing for game targeting criteria
/// Replaces Map<String, dynamic> to prevent runtime typos
@freezed
class TargetingCriteria with _$TargetingCriteria {
  const factory TargetingCriteria({
    int? minAge,
    int? maxAge,
    @Default(PlayerGender.any) PlayerGender gender,
    @Default(GameVibe.casual) GameVibe vibe,
  }) = _TargetingCriteria;

  factory TargetingCriteria.fromJson(Map<String, dynamic> json) =>
      _$TargetingCriteriaFromJson(json);
}
