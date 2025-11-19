import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:google_fonts/google_fonts.dart';

/// Weather Detail Screen - Shows detailed weather and air quality information
class WeatherDetailScreen extends ConsumerStatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  ConsumerState<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends ConsumerState<WeatherDetailScreen> {
  Position? _currentPosition;
  Map<String, dynamic>? _weatherData;
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

      // Call Cloud Function to get weather data
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions.httpsCallable('getHomeDashboardData').call({
        'lat': _currentPosition!.latitude,
        'lon': _currentPosition!.longitude,
      });

      final data = result.data as Map<String, dynamic>;
      
      setState(() {
        _weatherData = data;
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

  Color _getAQIColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    if (aqi <= 50) return Colors.green; // טוב
    if (aqi <= 100) return Colors.yellow.shade700; // בינוני
    if (aqi <= 150) return Colors.orange; // לא בריא לרגישים
    if (aqi <= 200) return Colors.red.shade700; // לא בריא
    if (aqi <= 300) return Colors.purple; // מאוד לא בריא
    return Colors.red.shade900; // מסוכן
  }

  String _getAQILabel(int? aqi) {
    if (aqi == null) return 'לא זמין';
    if (aqi <= 50) return 'מצוין';
    if (aqi <= 100) return 'טוב';
    if (aqi <= 150) return 'בינוני';
    if (aqi <= 200) return 'לא בריא';
    if (aqi <= 300) return 'מאוד לא בריא';
    return 'מסוכן';
  }

  String _getCloudCondition(String? condition) {
    if (condition == null) return 'ברור';
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('clear') || conditionLower.contains('sunny')) {
      return 'שמיים בהירים';
    } else if (conditionLower.contains('cloud') || conditionLower.contains('overcast')) {
      return 'מעונן';
    } else if (conditionLower.contains('rain') || conditionLower.contains('drizzle')) {
      return 'גשום';
    } else if (conditionLower.contains('storm') || conditionLower.contains('thunder')) {
      return 'סוער';
    } else if (conditionLower.contains('fog') || conditionLower.contains('mist')) {
      return 'ערפל';
    } else if (conditionLower.contains('snow')) {
      return 'שלג';
    }
    return 'מעונן חלקית';
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny;
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('clear') || conditionLower.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (conditionLower.contains('cloud')) {
      return Icons.wb_cloudy;
    } else if (conditionLower.contains('rain')) {
      return Icons.grain;
    } else if (conditionLower.contains('storm') || conditionLower.contains('thunder')) {
      return Icons.flash_on;
    } else if (conditionLower.contains('fog') || conditionLower.contains('mist')) {
      return Icons.blur_on;
    } else if (conditionLower.contains('snow')) {
      return Icons.ac_unit;
    }
    return Icons.wb_cloudy;
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
                      FuturisticCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Weather Icon
                            Icon(
                              _getWeatherIcon(_weatherData?['condition']),
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            // Temperature
                            if (_weatherData?['temperature'] != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_weatherData!['temperature']}',
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
                            ],
                            // Cloud Condition
                            Text(
                              _getCloudCondition(_weatherData?['condition']),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Vibe Message
                            if (_weatherData?['vibeMessage'] != null)
                              Text(
                                _weatherData!['vibeMessage'],
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Air Quality Card
                      FuturisticCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.air,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'איכות אוויר',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_weatherData?['aqiIndex'] != null) ...[
                              // AQI Value with Color
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: _getAQIColor(_weatherData!['aqiIndex']).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getAQIColor(_weatherData!['aqiIndex']).withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'מדד איכות אוויר',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '${_weatherData!['aqiIndex']}',
                                              style: GoogleFonts.inter(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: _getAQIColor(_weatherData!['aqiIndex']),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'AQI',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _getAQIColor(_weatherData!['aqiIndex']),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getAQILabel(_weatherData!['aqiIndex']),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // AQI Scale
                              _buildAQIScale(_weatherData!['aqiIndex']),
                            ] else ...[
                              Text(
                                'נתוני איכות אוויר לא זמינים',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
                            const Divider(height: 24),
                            if (_weatherData?['condition'] != null)
                              _buildDetailRow(
                                icon: Icons.wb_cloudy,
                                label: 'מצב עננים',
                                value: _getCloudCondition(_weatherData!['condition']),
                              ),
                            if (_weatherData?['timestamp'] != null) ...[
                              const Divider(height: 24),
                              _buildDetailRow(
                                icon: Icons.access_time,
                                label: 'עודכן לאחרונה',
                                value: _formatTimestamp(_weatherData!['timestamp']),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recommendations Card
                      if (_weatherData?['aqiIndex'] != null || _weatherData?['temperature'] != null)
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
                                    'המלצות',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._buildRecommendations(
                                _weatherData?['temperature'],
                                _weatherData?['aqiIndex'],
                                _weatherData?['condition'],
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

  Widget _buildAQIScale(int aqi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סולם איכות אוויר',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildScaleSegment(0, 50, Colors.green, 'מצוין', aqi),
            _buildScaleSegment(51, 100, Colors.yellow.shade700, 'טוב', aqi),
            _buildScaleSegment(101, 150, Colors.orange, 'בינוני', aqi),
            _buildScaleSegment(151, 200, Colors.red.shade700, 'לא בריא', aqi),
            _buildScaleSegment(201, 300, Colors.purple, 'מסוכן', aqi),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleSegment(int min, int max, Color color, String label, int currentAqi) {
    final isActive = currentAqi >= min && currentAqi <= max;
    return Expanded(
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
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

    // Air Quality recommendations
    if (aqi != null) {
      if (aqi > 100) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.air,
          text: 'איכות אוויר לא אופטימלית - שקול לדחות את המשחק',
          color: Colors.red,
        ));
      } else if (aqi <= 50) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.air,
          text: 'איכות אוויר מצוינת למשחק!',
          color: Colors.green,
        ));
      }
    }

    // Weather condition recommendations
    if (condition != null) {
      final conditionLower = condition.toLowerCase();
      if (conditionLower.contains('rain') || conditionLower.contains('storm')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.grain,
          text: 'גשום - בדוק את מצב המגרש לפני המשחק',
          color: Colors.blue,
        ));
      } else if (conditionLower.contains('clear') || conditionLower.contains('sunny')) {
        recommendations.add(_buildRecommendationItem(
          icon: Icons.wb_sunny,
          text: 'שמיים בהירים - תנאים מושלמים למשחק!',
          color: Colors.green,
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

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'לא זמין';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'עכשיו';
      } else if (difference.inMinutes < 60) {
        return 'לפני ${difference.inMinutes} דקות';
      } else if (difference.inHours < 24) {
        return 'לפני ${difference.inHours} שעות';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'לא זמין';
    }
  }
}

