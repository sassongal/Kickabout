/// Shared domain models used across multiple features
///
/// These models represent concepts that are used by 2+ features:
/// - Team: Used by Games and Hubs
/// - Venue: Used by Games and Hubs
/// - MatchResult: Used by Games and Hubs
/// - AgeGroup: Shared categorization

// Core shared models
export 'team.dart';
export 'venue.dart';
export 'match_result.dart';
export 'age_group.dart';

// Enums
export 'enums/game_status.dart';
export 'enums/game_visibility.dart';
export 'enums/signup_status.dart';
export 'enums/event_type.dart';
export 'enums/player_position.dart';

// Value objects
export 'value_objects/join_mode.dart';
export 'value_objects/match_logging_policy.dart';
export 'value_objects/geographic_point.dart';
export 'value_objects/entity_id.dart';
export 'value_objects/time_range.dart';
