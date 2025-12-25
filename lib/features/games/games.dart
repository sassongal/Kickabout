// Games Feature Barrel File
// Provides centralized exports for the games feature module
//
// This file will be populated as files are migrated to the feature structure.
// Phase 1: Foundation - Empty barrel file created

// Domain Models (Phase 2 - migrated)
export 'domain/models/match_record.dart';
export 'domain/models/session_logic.dart';
export 'domain/models/session_rotation.dart';
export 'domain/models/team_maker.dart';

// Domain Services (Phase 2 - migrated + existing)
export 'domain/services/live_match_permissions.dart';
export 'domain/services/event_action_service.dart';
export 'domain/services/game_finalization_service.dart';
export 'domain/services/game_signup_service.dart';

// Repositories (already exist)
export 'data/repositories/session_repository.dart';
export 'data/repositories/match_approval_repository.dart';
export 'data/repositories/game_queries_repository.dart';

// Use Cases (already exist)
export 'domain/use_cases/submit_game_use_case.dart';
export 'domain/use_cases/log_match_result_use_case.dart';
export 'domain/use_cases/log_past_game_use_case.dart';

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
