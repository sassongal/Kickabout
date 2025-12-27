import 'package:kattrick/features/location/infrastructure/services/location_service.dart';
import 'package:kattrick/services/weather_service.dart';

/// Dashboard data model containing weather and vibe information
class DashboardData {
  final String vibeMessage;
  final int? temperature;
  final String? condition;
  final String summary;
  final int? weatherCode;

  const DashboardData({
    required this.vibeMessage,
    this.temperature,
    this.condition,
    required this.summary,
    this.weatherCode,
  });

  /// Convert to Map for backward compatibility with existing providers
  Map<String, dynamic> toMap() {
    return {
      'vibeMessage': vibeMessage,
      'temperature': temperature,
      'condition': condition,
      'summary': summary,
      'weatherCode': weatherCode,
    };
  }
}

/// Service for fetching dashboard data (weather, vibe messages)
///
/// Extracts business logic from homeDashboardData provider to follow
/// domain service pattern. Providers should only handle state management.
class DashboardService {
  final LocationService _locationService;
  final WeatherService _weatherService;

  DashboardService({
    required LocationService locationService,
    required WeatherService weatherService,
  })  : _locationService = locationService,
        _weatherService = weatherService;

  /// Get dashboard data with weather and vibe message
  ///
  /// Returns default vibe message if location or weather unavailable.
  /// Uses Open-Meteo free weather API.
  Future<DashboardData> getDashboardData() async {
    try {
      final position = await _locationService.getCurrentLocation();

      // No location available - return default
      if (position == null) {
        return const DashboardData(
          vibeMessage: 'יום ענק לכדורגל! ⚽',
          temperature: null,
          condition: null,
          summary: 'יום ענק לכדורגל! ⚽',
        );
      }

      // Fetch weather for current location
      final weather = await _weatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Weather unavailable - return default
      if (weather == null) {
        return const DashboardData(
          vibeMessage: 'יום טוב לכדורגל! ☀️',
          temperature: null,
          condition: null,
          summary: 'יום טוב לכדורגל! ☀️',
        );
      }

      // Return weather-based data
      return DashboardData(
        vibeMessage: weather.summary,
        temperature: weather.temperature,
        condition: weather.condition,
        summary: weather.summary,
        weatherCode: weather.weatherCode,
      );
    } catch (e) {
      // Error fallback - return default message
      return const DashboardData(
        vibeMessage: 'יום טוב לכדורגל! ☀️',
        temperature: null,
        condition: null,
        summary: 'יום טוב לכדורגל! ☀️',
      );
    }
  }
}
