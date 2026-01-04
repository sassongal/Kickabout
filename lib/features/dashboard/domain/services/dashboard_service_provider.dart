import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/features/dashboard/domain/services/dashboard_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_service_provider.g.dart';

/// Provider for DashboardService
///
/// Extracts business logic from homeDashboardData provider
@riverpod
DashboardService dashboardService(DashboardServiceRef ref) {
  return DashboardService(
    locationService: ref.watch(locationServiceProvider),
    weatherService: ref.watch(weatherServiceProvider),
  );
}
