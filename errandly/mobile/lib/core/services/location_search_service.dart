import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

enum LocationSourceType {
  deviceGps,
  googlePlaces,
  manualPin,
}

class PlaceSearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final LocationSourceType sourceType;
  final double? accuracyRadius; // in meters if known

  const PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.sourceType = LocationSourceType.googlePlaces,
    this.accuracyRadius,
  });

  bool get isGpsExact => sourceType == LocationSourceType.deviceGps;

  String get sourceLabel {
    switch (sourceType) {
      case LocationSourceType.deviceGps:
        return accuracyRadius != null
            ? 'GPS (±${accuracyRadius!.toStringAsFixed(0)}m)'
            : 'Exact GPS';
      case LocationSourceType.googlePlaces:
        return 'Google Places';
      case LocationSourceType.manualPin:
        return 'Map Pin';
    }
  }

  @override
  String toString() => displayName;
}

/// Service resolving real-world place search autocomplete queries
/// and reverse-geocoding coordinates exclusively via Google Places & Geocoding.
class LocationSearchService {
  LocationSearchService._();

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent': 'ErrandlyApp/1.0 (com.errand.app)',
      'Accept': 'application/json',
    },
  ));

  /// Autocomplete search by query string strictly using Google Places.
  static Future<List<PlaceSearchResult>> search(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final targetLat = biasLat ?? AppConstants.defaultLat;
    final targetLng = biasLng ?? AppConstants.defaultLng;

    // Search exclusively using Google Places
    if (AppConstants.googleMapsApiKey.isNotEmpty) {
      try {
        final googleResults = await _searchGooglePlaces(cleanQuery, targetLat, targetLng);
        if (googleResults.isNotEmpty) {
          return googleResults;
        }
      } catch (e) {
        debugPrint('Google Places search error: $e');
      }
    }

    return [];
  }

  /// Helper to search Google Places Autocomplete and resolve coordinates.
  /// Supports modern Places API (New) with automatic fallback to Legacy Places API.
  static Future<List<PlaceSearchResult>> _searchGooglePlaces(
    String query,
    double biasLat,
    double biasLng,
  ) async {
    const apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty) return [];

    // 1. Try Google Places API (New)
    try {
      final newApiRes = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'input': query,
          'locationBias': {
            'circle': {
              'center': {
                'latitude': biasLat,
                'longitude': biasLng,
              },
              'radius': 50000.0,
            },
          },
          'includedRegionCodes': ['ng'],
        },
      );

      final data = newApiRes.data is String ? jsonDecode(newApiRes.data) : newApiRes.data;
      final suggestions = data['suggestions'] as List?;
      if (suggestions != null && suggestions.isNotEmpty) {
        final results = <PlaceSearchResult>[];
        for (final item in suggestions.take(6)) {
          final pred = item['placePrediction'];
          if (pred == null) continue;

          final placeId = (pred['placeId'] ?? pred['place']?.toString().replaceFirst('places/', ''))?.toString();
          final text = pred['text']?['text']?.toString() ?? '';
          final mainText = pred['structuredFormat']?['mainText']?['text']?.toString() ?? text.split(',').first;

          if (placeId != null) {
            try {
              final detailRes = await _dio.get(
                'https://places.googleapis.com/v1/places/$placeId',
                options: Options(
                  headers: {
                    'X-Goog-Api-Key': apiKey,
                    'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
                  },
                ),
              );
              final detailData = detailRes.data is String ? jsonDecode(detailRes.data) : detailRes.data;
              final loc = detailData['location'];
              if (loc != null) {
                final lat = (loc['latitude'] as num).toDouble();
                final lng = (loc['longitude'] as num).toDouble();
                final displayName = detailData['formattedAddress']?.toString() ?? text;
                final name = detailData['displayName']?['text']?.toString() ?? mainText;

                results.add(PlaceSearchResult(
                  name: name,
                  displayName: displayName,
                  latitude: lat,
                  longitude: lng,
                  sourceType: LocationSourceType.googlePlaces,
                ));
              }
            } catch (_) {}
          }
        }
        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('Places API (New) error: $e, trying legacy Places API');
    }

    // 2. Try Legacy Google Places API
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': apiKey,
          'components': 'country:ng',
          'location': '$biasLat,$biasLng',
          'radius': 50000,
        },
      );

      final data = res.data is String ? jsonDecode(res.data) : res.data;
      final predictions = data['predictions'] as List?;
      if (predictions != null && predictions.isNotEmpty) {
        final results = <PlaceSearchResult>[];
        for (final pred in predictions.take(6)) {
          final placeId = pred['place_id']?.toString();
          final description = pred['description']?.toString() ?? '';
          final mainText = pred['structured_formatting']?['main_text']?.toString() ?? description.split(',').first;

          if (placeId != null) {
            try {
              final detailRes = await _dio.get(
                'https://maps.googleapis.com/maps/api/place/details/json',
                queryParameters: {
                  'place_id': placeId,
                  'fields': 'geometry,name',
                  'key': apiKey,
                },
              );
              final detailData = detailRes.data is String ? jsonDecode(detailRes.data) : detailRes.data;
              final location = detailData['result']?['geometry']?['location'];
              if (location != null) {
                final lat = (location['lat'] as num).toDouble();
                final lng = (location['lng'] as num).toDouble();
                results.add(PlaceSearchResult(
                  name: mainText,
                  displayName: description,
                  latitude: lat,
                  longitude: lng,
                  sourceType: LocationSourceType.googlePlaces,
                ));
              }
            } catch (_) {}
          }
        }
        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('Legacy Places API error: $e');
    }

    // 3. Fallback to Google Geocoding API if autocomplete prediction coordinates couldn't be resolved
    try {
      final res = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': query,
          'key': apiKey,
          'components': 'country:ng',
        },
      );
      final data = res.data is String ? jsonDecode(res.data) : res.data;
      final results = data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return results.take(4).map((r) {
          final formatted = r['formatted_address']?.toString() ?? query;
          final loc = r['geometry']?['location'];
          final lat = (loc?['lat'] as num?)?.toDouble() ?? biasLat;
          final lng = (loc?['lng'] as num?)?.toDouble() ?? biasLng;
          return PlaceSearchResult(
            name: formatted.split(',').first,
            displayName: formatted,
            latitude: lat,
            longitude: lng,
            sourceType: LocationSourceType.googlePlaces,
          );
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Reverse geocode coordinates (lat, lng) strictly via Google Geocoding.
  static Future<PlaceSearchResult?> reverseGeocode(double lat, double lng) async {
    // 1. Try Google Geocoding API if key configured
    if (AppConstants.googleMapsApiKey.isNotEmpty) {
      try {
        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          queryParameters: {
            'latlng': '$lat,$lng',
            'key': AppConstants.googleMapsApiKey,
          },
        );
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results.first;
          final formatted = first['formatted_address']?.toString() ?? '';
          final name = formatted.split(',').first;
          return PlaceSearchResult(
            name: name,
            displayName: formatted,
            latitude: lat,
            longitude: lng,
            sourceType: LocationSourceType.googlePlaces,
          );
        }
      } catch (e) {
        debugPrint('Google Geocoding error: $e');
      }
    }

    // 2. Fallback to platform native geocoding (iOS / Android system geocoder)
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
          if (p.country != null && p.country!.isNotEmpty) p.country,
        ];
        final display = parts.join(', ');
        return PlaceSearchResult(
          name: p.street ?? p.name ?? 'Selected Location',
          displayName: display.isNotEmpty ? display : 'Pinned Location',
          latitude: lat,
          longitude: lng,
          city: p.locality,
          state: p.administrativeArea,
          sourceType: LocationSourceType.manualPin,
        );
      }
    } catch (_) {}

    // 3. Final coordinate fallback
    return PlaceSearchResult(
      name: 'Pinned Location',
      displayName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      latitude: lat,
      longitude: lng,
      sourceType: LocationSourceType.manualPin,
    );
  }
}
