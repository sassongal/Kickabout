// DEPRECATED Barrel file for all models
// This file is maintained for backward compatibility during migration
// Please import models directly from their feature modules instead

// Profile Feature
export 'package:kattrick/features/profile/domain/models/user.dart';
export 'package:kattrick/features/profile/domain/models/player.dart';
export 'package:kattrick/features/profile/domain/models/player_stats.dart';

// Hubs Feature
export 'package:kattrick/features/hubs/domain/models/hub.dart';
export 'package:kattrick/features/hubs/domain/models/hub_member.dart';
export 'package:kattrick/features/hubs/domain/models/hub_event.dart';
export 'package:kattrick/features/hubs/domain/models/hub_role.dart';
export 'package:kattrick/features/hubs/domain/models/hub_settings.dart';
export 'package:kattrick/features/hubs/domain/models/poll.dart';

// Social Feature
export 'package:kattrick/features/social/domain/models/feed_post.dart';
export 'package:kattrick/features/social/domain/models/comment.dart';
export 'package:kattrick/features/social/domain/models/chat_message.dart';
export 'package:kattrick/features/social/domain/models/notification.dart';
export 'package:kattrick/features/social/domain/models/private_message.dart';
export 'package:kattrick/features/social/domain/models/contact_message.dart';

// Gamification Feature
export 'package:kattrick/features/gamification/domain/models/gamification.dart';

// Venues Feature
export 'package:kattrick/features/venues/domain/models/venue.dart';

// Games Feature
export 'package:kattrick/features/games/domain/models/game.dart';
export 'package:kattrick/features/games/domain/models/game_session.dart';
export 'package:kattrick/features/games/domain/models/game_denormalized_data.dart';
export 'package:kattrick/features/games/domain/models/game_audit.dart';
export 'package:kattrick/features/games/domain/models/game_audit_event.dart';
export 'package:kattrick/features/games/domain/models/game_signup.dart';
export 'package:kattrick/features/games/domain/models/game_event.dart';
export 'package:kattrick/features/games/domain/models/game_result.dart';
export 'package:kattrick/features/games/domain/models/log_past_game_details.dart';
export 'package:kattrick/features/games/domain/models/rotation_state.dart';

// Shared Models
export 'package:kattrick/shared/domain/models/age_group.dart';
export 'package:kattrick/shared/domain/models/team.dart';
export 'package:kattrick/shared/domain/models/team_data.dart';
export 'package:kattrick/shared/domain/models/match_result.dart';
export 'package:kattrick/shared/domain/models/rating_snapshot.dart';
export 'package:kattrick/shared/domain/models/pro_team.dart';
export 'package:kattrick/shared/infrastructure/firestore/paginated_result.dart';
export 'package:kattrick/shared/domain/models/targeting_criteria.dart';
export 'package:kattrick/shared/domain/models/venue_edit_request.dart';

// Shared Enums
export 'package:kattrick/shared/domain/models/enums/game_status.dart';
export 'package:kattrick/shared/domain/models/enums/game_visibility.dart';
export 'package:kattrick/shared/domain/models/enums/signup_status.dart';
export 'package:kattrick/shared/domain/models/enums/event_type.dart';
export 'package:kattrick/shared/domain/models/enums/player_position.dart';

// Shared Converters (in infrastructure layer)
export 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';
export 'package:kattrick/shared/infrastructure/firestore/converters/geopoint_firestore_converter.dart';

// Shared Value Objects
export 'package:kattrick/shared/domain/models/value_objects/join_mode.dart';
export 'package:kattrick/shared/domain/models/value_objects/match_logging_policy.dart';
export 'package:kattrick/shared/domain/models/value_objects/notification_preferences.dart';
export 'package:kattrick/shared/domain/models/value_objects/privacy_settings.dart';
export 'package:kattrick/shared/domain/models/value_objects/user_location.dart';
