import 'package:freezed_annotation/freezed_annotation.dart';

part 'rotation_state.freezed.dart';
part 'rotation_state.g.dart';

/// RotationState - represents the current state of team rotation in a session
/// Used for "Winner Stays" (King of the Pitch) format with 2-8 teams
@freezed
class RotationState with _$RotationState {
  const factory RotationState({
    /// Team A currently playing (color identifier)
    required String teamAColor,

    /// Team B currently playing (color identifier)
    required String teamBColor,

    /// Queue of teams waiting to play (ordered by when they rotated out)
    /// Empty for 2-team sessions (no rotation needed)
    @Default([]) List<String> waitingTeamColors,

    /// Current match number in the session (starts at 1)
    @Default(1) int currentMatchNumber,
  }) = _RotationState;

  factory RotationState.fromJson(Map<String, dynamic> json) =>
      _$RotationStateFromJson(json);
}
