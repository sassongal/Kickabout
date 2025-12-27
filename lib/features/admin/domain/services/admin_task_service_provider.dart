import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/features/admin/domain/services/admin_task_service.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';

part 'admin_task_service_provider.g.dart';

/// Provider for AdminTaskService
///
/// Extracts business logic from adminTasks provider
@riverpod
AdminTaskService adminTaskService(AdminTaskServiceRef ref) {
  return AdminTaskService(
    hubsRepo: ref.watch(hubsRepositoryProvider),
    gameQueriesRepo: ref.watch(gameQueriesRepositoryProvider),
  );
}
