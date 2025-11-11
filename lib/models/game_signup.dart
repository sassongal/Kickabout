import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/enums/signup_status.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

part 'game_signup.freezed.dart';
part 'game_signup.g.dart';

/// Game signup model matching Firestore schema: /games/{id}/signups/{uid}
@freezed
class GameSignup with _$GameSignup {
  const factory GameSignup({
    required String playerId,
    @TimestampConverter() required DateTime signedUpAt,
    @SignupStatusConverter() @Default(SignupStatus.pending) SignupStatus status,
  }) = _GameSignup;

  factory GameSignup.fromJson(Map<String, dynamic> json) =>
      _$GameSignupFromJson(json);
}

/// Firestore converter for GameSignup
class GameSignupConverter
    implements JsonConverter<GameSignup, Map<String, dynamic>> {
  const GameSignupConverter();

  @override
  GameSignup fromJson(Map<String, dynamic> json) => GameSignup.fromJson(json);

  @override
  Map<String, dynamic> toJson(GameSignup object) => object.toJson();
}

/// SignupStatus converter for Firestore
class SignupStatusConverter implements JsonConverter<SignupStatus, String> {
  const SignupStatusConverter();

  @override
  SignupStatus fromJson(String json) => SignupStatus.fromFirestore(json);

  @override
  String toJson(SignupStatus object) => object.toFirestore();
}

