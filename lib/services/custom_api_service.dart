import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/venue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for custom API integration
/// This service allows you to integrate with your own API endpoints
class CustomApiService {
  final String? baseUrl;
  final String? apiKey;
  final http.Client _httpClient;

  CustomApiService({
    String? baseUrl,
    String? apiKey,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? Env.customApiBaseUrl,
        apiKey = apiKey ?? Env.customApiKey,
        _httpClient = httpClient ?? http.Client();

  /// Check if custom API is configured
  bool get isConfigured => baseUrl != null && baseUrl!.isNotEmpty;

  /// Search venues using custom API
  Future<List<Venue>> searchVenues({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? query,
  }) async {
    if (!isConfigured) {
      throw Exception('Custom API not configured');
    }

    try {
      final url = Uri.parse('$baseUrl/venues/search');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

      final body = json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        if (query != null) 'query': query,
      });

      final response = await _httpClient.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Custom API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final venues = <Venue>[];

      for (final item in data['venues'] ?? []) {
        venues.add(Venue.fromJson(item));
      }

      return venues;
    } catch (e) {
      throw Exception('Failed to search venues: $e');
    }
  }

  /// Get venue details from custom API
  Future<Venue?> getVenueDetails(String venueId) async {
    if (!isConfigured) {
      throw Exception('Custom API not configured');
    }

    try {
      final url = Uri.parse('$baseUrl/venues/$venueId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

      final response = await _httpClient.get(url, headers: headers);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      return Venue.fromJson(data['venue']);
    } catch (e) {
      return null;
    }
  }

  /// Sync venue data with custom API
  Future<void> syncVenue(Venue venue) async {
    if (!isConfigured) {
      throw Exception('Custom API not configured');
    }

    try {
      final url = Uri.parse('$baseUrl/venues/sync');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

      final body = json.encode(venue.toJson());

      final response = await _httpClient.post(url, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Custom API sync error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to sync venue: $e');
    }
  }
}

