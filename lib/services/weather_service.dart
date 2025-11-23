import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/// Weather Service using Open-Meteo (Free API)
/// Maps WMO weather codes to football context phrases
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Get current weather for a location
  Future<WeatherData?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&timezone=auto',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseCurrentWeather(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get weather forecast for a specific date and location
  Future<WeatherData?> getWeatherForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&daily=weather_code,temperature_2m_max,temperature_2m_min&start_date=$dateStr&end_date=$dateStr&timezone=auto',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseForecastWeather(data, date);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get 7-day forecast
  Future<List<WeatherData>> get7DayForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final endDate = DateTime.now().add(const Duration(days: 7));
      final startDateStr = DateTime.now().toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude&daily=weather_code,temperature_2m_max,temperature_2m_min&start_date=$startDateStr&end_date=$endDateStr&timezone=auto',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parse7DayForecast(data);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Parse current weather from API response
  WeatherData _parseCurrentWeather(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>?;
    if (current == null) return _defaultWeather();

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
    final code = current['weather_code'] as int? ?? 0;

    return WeatherData(
      temperature: temp.round(),
      weatherCode: code,
      condition: _getFootballCondition(code, temp),
      summary: _getWeatherSummary(code, temp),
    );
  }

  /// Parse forecast weather for specific date
  WeatherData _parseForecastWeather(Map<String, dynamic> data, DateTime date) {
    final daily = data['daily'] as Map<String, dynamic>?;
    if (daily == null) return _defaultWeather();

    final dates = daily['time'] as List<dynamic>?;
    final codes = daily['weather_code'] as List<dynamic>?;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>?;

    if (dates == null || codes == null || maxTemps == null || minTemps == null) {
      return _defaultWeather();
    }

    final dateStr = date.toIso8601String().split('T')[0];
    final index = dates.indexWhere((d) => d.toString().startsWith(dateStr));

    if (index == -1) return _defaultWeather();

    final code = (codes[index] as num?)?.toInt() ?? 0;
    final maxTemp = (maxTemps[index] as num?)?.toDouble() ?? 20.0;
    final minTemp = (minTemps[index] as num?)?.toDouble() ?? 15.0;
    final avgTemp = (maxTemp + minTemp) / 2;

    return WeatherData(
      temperature: avgTemp.round(),
      weatherCode: code,
      condition: _getFootballCondition(code, avgTemp),
      summary: _getWeatherSummary(code, avgTemp),
      maxTemperature: maxTemp.round(),
      minTemperature: minTemp.round(),
    );
  }

  /// Parse 7-day forecast
  List<WeatherData> _parse7DayForecast(Map<String, dynamic> data) {
    final daily = data['daily'] as Map<String, dynamic>?;
    if (daily == null) return [];

    final dates = daily['time'] as List<dynamic>?;
    final codes = daily['weather_code'] as List<dynamic>?;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>?;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>?;

    if (dates == null || codes == null || maxTemps == null || minTemps == null) {
      return [];
    }

    final forecast = <WeatherData>[];
    for (int i = 0; i < dates.length && i < 7; i++) {
      final dateStr = dates[i].toString();
      final code = (codes[i] as num?)?.toInt() ?? 0;
      final maxTemp = (maxTemps[i] as num?)?.toDouble() ?? 20.0;
      final minTemp = (minTemps[i] as num?)?.toDouble() ?? 15.0;
      final avgTemp = (maxTemp + minTemp) / 2;

      forecast.add(WeatherData(
        temperature: avgTemp.round(),
        weatherCode: code,
        condition: _getFootballCondition(code, avgTemp),
        summary: _getWeatherSummary(code, avgTemp),
        maxTemperature: maxTemp.round(),
        minTemperature: minTemp.round(),
        date: DateTime.tryParse(dateStr),
      ));
    }

    return forecast;
  }

  /// Map WMO weather code to football context condition
  String _getFootballCondition(int code, double temp) {
    // Clear sky
    if (code == 0) {
      if (temp > 30) return 'Heat Warning ☀️';
      if (temp < 5) return 'Cold Conditions ❄️';
      return 'Ideal Conditions ⚽';
    }

    // Partly cloudy
    if (code == 1 || code == 2) {
      return 'Good Conditions ⛅';
    }

    // Cloudy
    if (code == 3) {
      return 'Overcast ⛅';
    }

    // Fog
    if (code == 45 || code == 48) {
      return 'Low Visibility 🌫️';
    }

    // Drizzle
    if (code >= 51 && code <= 55) {
      return 'Light Rain 🌦️';
    }

    // Rain
    if (code >= 61 && code <= 67) {
      return 'Slippery Pitch 🌧️';
    }

    // Snow
    if (code >= 71 && code <= 77) {
      return 'Snow Conditions ❄️';
    }

    // Thunderstorm
    if (code >= 95 && code <= 99) {
      return 'Dangerous Conditions ⚠️';
    }

    return 'Check Conditions ⚽';
  }

  /// Get weather summary for display
  String _getWeatherSummary(int code, double temp) {
    final condition = _getFootballCondition(code, temp);
    
    if (temp > 30) {
      return '$temp°C - חם מדי למשחק';
    } else if (temp < 5) {
      return '$temp°C - קר מדי למשחק';
    } else if (code == 0) {
      return '$temp°C - מושלם למשחק';
    } else if (code >= 61 && code <= 67) {
      return '$temp°C - מגרש חלקלק';
    } else if (code >= 95 && code <= 99) {
      return '$temp°C - תנאים מסוכנים';
    } else {
      return '$temp°C - $condition';
    }
  }

  WeatherData _defaultWeather() {
    return WeatherData(
      temperature: 20,
      weatherCode: 0,
      condition: 'Ideal Conditions ⚽',
      summary: '20°C - מושלם למשחק',
    );
  }
}

/// Weather data model
class WeatherData {
  final int temperature;
  final int weatherCode;
  final String condition;
  final String summary;
  final int? maxTemperature;
  final int? minTemperature;
  final DateTime? date;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.summary,
    this.maxTemperature,
    this.minTemperature,
    this.date,
  });
}

