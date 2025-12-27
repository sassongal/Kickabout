// Hubs Feature Barrel File
// Provides centralized exports for the hubs feature module

// Domain Models (Phase 5 - migrated)
export 'domain/models/hub.dart';
export 'domain/models/hub_member.dart';
export 'domain/models/hub_event.dart';
export 'domain/models/hub_role.dart';
export 'domain/models/hub_settings.dart';
export 'domain/models/poll.dart';

// Repositories (Phase 4 - migrated + additions)
export 'data/repositories/hubs_repository.dart';
export 'data/repositories/hub_events_repository.dart';
export 'data/repositories/polls_repository.dart';
export 'data/repositories/events_repository.dart';

// Domain Services (Phase 4 - migrated + additions)
export 'domain/services/hub_creation_service.dart';
export 'domain/services/hub_permissions_service.dart';
export 'domain/services/hub_venue_matcher_service.dart';
export 'domain/services/hub_membership_service.dart';
export 'domain/services/player_merge_service.dart';

// Infrastructure Services (moved from domain)
export 'infrastructure/services/hub_analytics_service.dart';

// Notifiers (will be created in Phase 5)
// export 'presentation/notifiers/hub_events_tab_notifier.dart';
// export 'presentation/notifiers/hub_settings_notifier.dart';
// export 'presentation/notifiers/create_hub_notifier.dart';

// Screens (will be moved in Phase 5)
// export 'presentation/screens/hub_list_screen.dart';
// export 'presentation/screens/hub_detail_screen.dart';
// ... etc
