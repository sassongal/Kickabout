import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/services/weather_service.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Weather Detail Screen - Shows detailed weather and air quality information
class WeatherDetailScreen extends ConsumerStatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  ConsumerState<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends ConsumerState<WeatherDetailScreen> {
  Position? _currentPosition;
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final weatherService = ref.read(weatherServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        // Use default location (Jerusalem) if no position available
        _currentPosition = Position(
          latitude: 31.7683,
          longitude: 35.2137,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        _currentPosition = position;
      }

      // Get current weather and 7-day forecast
      final current = await weatherService.getCurrentWeather(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      final forecast = await weatherService.get7DayForecast(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      
      setState(() {
        _currentWeather = current;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading weather data: $e');
      setState(() {
        _error = 'שגיאה בטעינת נתוני מזג האוויר';
        _isLoading = false;
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.contains('☀️') || condition.contains('Ideal')) {
      return Icons.wb_sunny;
    } else if (condition.contains('🌧️') || condition.contains('Slippery')) {
      return Icons.grain;
    } else if (condition.contains('⚠️') || condition.contains('Dangerous')) {
      return Icons.flash_on;
    } else if (condition.contains('🌫️') || condition.contains('Visibility')) {
      return Icons.blur_on;
    } else if (condition.contains('❄️') || condition.contains('Snow')) {
      return Icons.ac_unit;
    } else if (condition.contains('⛅') || condition.contains('Cloud')) {
      return Icons.wb_cloudy;
    }
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'תנאי מזג אוויר לכדורגל',
      showBottomNav: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _loadWeatherData,
        ),
      ],
      body: _isLoading
          ? const FuturisticLoadingState(message: 'טוען נתוני מזג אוויר...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadWeatherData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with Main Info
                      if (_currentWeather != null)
                        FuturisticCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Weather Icon
                              Icon(
                                _getWeatherIcon(_currentWeather!.condition),
                                size: 80,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              // Temperature
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_currentWeather!.temperature}',
                                    style: GoogleFonts.inter(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '°C',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Condition
                              Text(
                                _currentWeather!.condition,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Summary
                              Text(
                                _currentWeather!.summary,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 7-Day Forecast
                      if (_forecast.isNotEmpty) ...[
                        FuturisticCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'תחזית 7 ימים',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._forecast.map((weather) => _buildForecastItem(weather)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),

                      // Weather Details Card
                      FuturisticCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'פרטים נוספים',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              icon: Icons.location_on,
                              label: 'מיקום',
                              value: _currentPosition != null
                                  ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                  : 'לא זמין',
                            ),
                            if (_currentWeather != null) ...[
                              const Divider(height: 24),
                              _buildDetailRow(
                                icon: Icons.wb_cloudy,
                                label: 'תנאים',
                                value: _currentWeather!.condition,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recommendations Card
                      if (_currentWeather != null)
                        FuturisticCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Theme.of(context).colorScheme.secondary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'המלצות למשחק',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._buildRecommendations(
                                _currentWeather!.temperature,
                                null, // AQI not available from Open-Meteo
                                _currentWeather!.condition,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(WeatherData weather) {
    final dateStr = weather.date != null
        ? DateFormat('EEEE, d MMM', 'he').format(weather.date!)
        : 'היום';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateStr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            weather.condition.split(' ').last, // Emoji
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          if (weather.maxTemperature != null && weather.minTemperature != null)
            Text(
              '${weather.maxTemperature}°/${weather.minTemperature}°',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${weather.temperature}°C',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRecommendations(int? temp, int? aqi, String? condition) {
    final recommendations = <Widget>[];

    // Temperature recommendations
    if (temp != null) {
      if (temp < 10) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.ac_unit,
          text: 'קר מאוד - הקפד על חימום לפני המשחק',
          color: Colors.blue,
        ));
      } else if (temp > 30) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.wb_sunny,
          text: 'חם מאוד - שתה הרבה מים והקפד על הפסקות',
          color: Colors.orange,
        ));
      } else if (temp >= 20 && temp <= 25) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.check_circle,
          text: 'טמפרטורה מושלמת למשחק כדורגל!',
          color: Colors.green,
        ));
      }
    }

    // Weather condition recommendations
    if (condition != null) {
      if (condition.contains('🌧️') || condition.contains('Slippery')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.grain,
          text: 'גשום - בדוק את מצב המגרש לפני המשחק',
          color: Colors.blue,
        ));
      } else if (condition.contains('⚽') || condition.contains('Ideal')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.check_circle,
          text: 'תנאים מושלמים למשחק כדורגל!',
          color: Colors.green,
        ));
      } else if (condition.contains('⚠️') || condition.contains('Dangerous')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.warning,
          text: 'תנאים מסוכנים - מומלץ לדחות את המשחק',
          color: Colors.red,
        ));
      } else if (condition.contains('☀️') || condition.contains('Heat')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.wb_sunny,
          text: 'חם מאוד - הקפד על שתייה והפסקות',
          color: Colors.orange,
        ));
      } else if (condition.contains('❄️') || condition.contains('Cold')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.ac_unit,
          text: 'קר מאוד - הקפד על חימום לפני המשחק',
          color: Colors.blue,
        ));
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(_buildRecommendationItem(
        icon: Icons.info,
        text: 'תנאי מזג האוויר סבירים למשחק',
        color: Colors.grey,
      ));
    }

    return recommendations;
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

}

