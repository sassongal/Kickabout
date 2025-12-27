// Shared Module Barrel File
// Provides centralized exports for shared infrastructure and domain models
// that are used across multiple features

// Domain Models
export 'domain/models/age_group.dart';
export 'domain/models/team.dart';
export 'domain/models/team_data.dart';
export 'domain/models/match_result.dart';
export 'domain/models/rating_snapshot.dart';
export 'domain/models/pro_team.dart';
export 'domain/models/targeting_criteria.dart';
export 'domain/models/venue_edit_request.dart';

// Domain Enums
export 'domain/models/enums/game_status.dart';
export 'domain/models/enums/game_visibility.dart';
export 'domain/models/enums/signup_status.dart';
export 'domain/models/enums/event_type.dart';
export 'domain/models/enums/player_position.dart';

// Domain Value Objects
export 'domain/models/value_objects/join_mode.dart';
export 'domain/models/value_objects/match_logging_policy.dart';
export 'domain/models/value_objects/notification_preferences.dart';
export 'domain/models/value_objects/privacy_settings.dart';
export 'domain/models/value_objects/user_location.dart';
export 'domain/models/value_objects/geographic_point.dart';
export 'domain/models/value_objects/entity_id.dart';
export 'domain/models/value_objects/time_range.dart';

// Infrastructure Firestore Utilities (moved from domain)
export 'infrastructure/firestore/paginated_result.dart';
export 'infrastructure/firestore/converters/timestamp_firestore_converter.dart';
export 'infrastructure/firestore/converters/geopoint_firestore_converter.dart';
export 'infrastructure/firestore/converters/geographic_point_firestore_converter.dart';

// Domain Events
export 'domain/events/domain_event.dart';
export 'domain/events/event_bus.dart';
export 'domain/events/game_events.dart';
export 'domain/events/hub_events.dart';

// Infrastructure Services
export 'infrastructure/cache/cache_service.dart';
export 'infrastructure/cache/cache_invalidation_service.dart';
export 'infrastructure/analytics/analytics_service.dart';
export 'infrastructure/logging/error_handler_service.dart';
export 'infrastructure/monitoring/monitoring_service.dart';
