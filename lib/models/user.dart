import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model matching Firestore schema: /users/{uid}
@freezed
class User with _$User {
  const factory User({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? phoneNumber,
    @TimestampConverter() required DateTime createdAt,
    @Default([]) List<String> hubIds,
    @Default(5.0) double currentRankScore,
    @Default('Midfielder') String preferredPosition,
    @Default(0) int totalParticipations,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Firestore converter for User
class UserConverter implements JsonConverter<User, Map<String, dynamic>> {
  const UserConverter();

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User object) => object.toJson();
}

