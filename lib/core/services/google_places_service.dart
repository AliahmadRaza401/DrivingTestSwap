import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/google_maps_key.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String primaryText;
  final String secondaryText;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? const {};
    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryText:
          formatting['main_text'] as String? ??
          (json['description'] as String? ?? ''),
      secondaryText: formatting['secondary_text'] as String? ?? '',
    );
  }
}

class PlaceDetails {
  const PlaceDetails({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class GooglePlacesService {
  GooglePlacesService._();

  static final http.Client _client = http.Client();

  static Future<List<PlaceSuggestion>> autocomplete(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': trimmed,
          'types': 'establishment',
          'components': 'country:gb',
          'key': googleMapsApiKey,
        });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Unable to search test centres right now.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status == 'ZERO_RESULTS') return const [];
    if (status != 'OK') {
      final error = json['error_message'] as String?;
      throw Exception(error ?? 'Failed to load location suggestions.');
    }

    final predictions = json['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .map((item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>))
        .where((item) => item.placeId.isNotEmpty)
        .toList();
  }

  static Future<PlaceDetails> getPlaceDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'name,geometry/location',
        'key': googleMapsApiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Unable to load the selected test centre.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      final error = json['error_message'] as String?;
      throw Exception(error ?? 'Failed to load test centre details.');
    }

    final result = json['result'] as Map<String, dynamic>? ?? const {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? const {};
    final location = geometry['location'] as Map<String, dynamic>? ?? const {};

    return PlaceDetails(
      name: result['name'] as String? ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
