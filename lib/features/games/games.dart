// Games Feature Barrel File
// Provides centralized exports for the games feature module

// Domain Models (Phase 2 & Phase 5 - migrated)
export 'domain/models/match_record.dart';
export 'domain/models/session_logic.dart';
export 'domain/models/session_rotation.dart';
export 'domain/models/team_maker.dart';
export 'domain/models/game.dart';
export 'domain/models/game_session.dart';
export 'domain/models/game_denormalized_data.dart';
export 'domain/models/game_audit.dart';
export 'domain/models/game_audit_event.dart';
export 'domain/models/game_signup.dart';
export 'domain/models/game_event.dart';
export 'domain/models/game_result.dart';
export 'domain/models/log_past_game_details.dart';
export 'domain/models/rotation_state.dart';

// Domain Services (Phase 2 - migrated + existing + Phase 4 additions)
export 'domain/services/live_match_permissions.dart';
export 'domain/services/game_reminder_service.dart';

// Infrastructure Services (moved from domain)
export 'infrastructure/services/event_action_service.dart';
export 'infrastructure/services/game_finalization_service.dart';
export 'infrastructure/services/game_signup_service.dart';
export 'infrastructure/services/game_management_service.dart';

// Repositories (already exist + Phase 4 additions)
export 'data/repositories/session_repository.dart';
export 'data/repositories/match_approval_repository.dart';
export 'data/repositories/game_queries_repository.dart';
export 'data/repositories/signups_repository.dart';
export 'data/repositories/game_teams_repository.dart';

// Use Cases (already exist)
export 'domain/use_cases/submit_game_use_case.dart';
export 'domain/use_cases/log_past_game_use_case.dart';

// Infrastructure Use Cases (moved from domain)
export 'infrastructure/use_cases/log_match_result_use_case.dart';

// Notifiers (some exist, some will be created)
export 'presentation/notifiers/log_game_notifier.dart';
export 'presentation/notifiers/log_past_game_notifier.dart';
export 'presentation/notifiers/log_match_result_dialog_notifier.dart';
// export 'presentation/notifiers/live_match_notifier.dart';
// export 'presentation/notifiers/team_maker_notifier.dart';
// export 'presentation/notifiers/game_session_notifier.dart';

// Screens (will be populated in Phase 3)
// export 'presentation/screens/game_list_screen.dart';
// export 'presentation/screens/game_detail_screen.dart';
// ... etc
