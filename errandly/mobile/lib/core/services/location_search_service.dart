import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

enum LocationSourceType {
  deviceGps,
  googlePlaces,
  openStreetMap,
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
    this.sourceType = LocationSourceType.openStreetMap,
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
      case LocationSourceType.openStreetMap:
        return 'OpenStreetMap';
      case LocationSourceType.manualPin:
        return 'Map Pin';
    }
  }

  @override
  String toString() => displayName;
}

/// Service resolving real-world place search autocomplete queries
/// and reverse-geocoding coordinates with multi-tiered fallback:
/// Google Places (optional) -> Photon (OSM) -> Nominatim -> Native Geocoding.
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

  /// Autocomplete search by query string (streets, landmarks, markets, cities).
  static Future<List<PlaceSearchResult>> search(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final targetLat = biasLat ?? AppConstants.defaultLat;
    final targetLng = biasLng ?? AppConstants.defaultLng;

    // 1. Try Google Places API if API key is configured
    if (AppConstants.googleMapsApiKey.isNotEmpty) {
      try {
        final googleResults = await _searchGooglePlaces(cleanQuery, targetLat, targetLng);
        if (googleResults.isNotEmpty) {
          return googleResults;
        }
      } catch (e) {
        debugPrint('Google Places search error: $e, falling back to OSM');
      }
    }

    final results = <PlaceSearchResult>[];

    // 2. Try Photon (OpenStreetMap based, fast, geocoding engine)
    try {
      final res = await _dio.get(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': cleanQuery,
          'limit': 8,
          'lat': targetLat,
          'lon': targetLng,
        },
      );

      final data = res.data is String ? jsonDecode(res.data) : res.data;
      if (data is Map && data['features'] is List) {
        for (final feature in data['features']) {
          final geom = feature['geometry'];
          final props = feature['properties'] ?? {};
          final coords = geom?['coordinates'] as List?;
          if (coords != null && coords.length >= 2) {
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();

            final name = (props['name'] ?? props['street'] ?? cleanQuery).toString();
            final street = props['street']?.toString();
            final city = (props['city'] ?? props['town'] ?? props['village'] ?? props['county'])?.toString();
            final state = props['state']?.toString();
            final country = props['country']?.toString();

            final parts = <String>[];
            if (name.isNotEmpty) parts.add(name);
            if (street != null && street != name) parts.add(street);
            if (city != null) parts.add(city);
            if (state != null) parts.add(state);
            if (country != null) parts.add(country);

            final display = parts.join(', ');

            results.add(PlaceSearchResult(
              name: name,
              displayName: display.isNotEmpty ? display : name,
              latitude: lat,
              longitude: lng,
              city: city,
              state: state,
              sourceType: LocationSourceType.openStreetMap,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('LocationSearchService Photon error: $e');
    }

    if (results.isNotEmpty) return results;

    // 3. Fallback to OpenStreetMap Nominatim search
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'q': cleanQuery,
          'limit': 6,
          'addressdetails': 1,
        },
      );

      final data = res.data is String ? jsonDecode(res.data) : res.data;
      if (data is List) {
        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final displayName = item['display_name']?.toString() ?? cleanQuery;
          final name = (item['name'] ?? displayName.split(',').first).toString();

          if (lat != null && lon != null) {
            final addr = item['address'] as Map?;
            results.add(PlaceSearchResult(
              name: name,
              displayName: displayName,
              latitude: lat,
              longitude: lon,
              city: addr?['city'] ?? addr?['town'] ?? addr?['county'],
              state: addr?['state'],
              sourceType: LocationSourceType.openStreetMap,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('LocationSearchService Nominatim fallback error: $e');
    }

    return results;
  }

  /// Helper to search Google Places Autocomplete and resolve coordinates
  static Future<List<PlaceSearchResult>> _searchGooglePlaces(
    String query,
    double biasLat,
    double biasLng,
  ) async {
    const apiKey = AppConstants.googleMapsApiKey;
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
    if (predictions == null || predictions.isEmpty) return [];

    final results = <PlaceSearchResult>[];
    // Resolve coordinates for up to top 4 predictions
    for (final pred in predictions.take(4)) {
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
    return results;
  }

  /// Reverse geocode coordinates (lat, lng) into a structured place result.
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
        debugPrint('Google Geocoding error: $e, falling back to OSM');
      }
    }

    // 2. Try Nominatim Reverse
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'addressdetails': 1,
        },
      );
      final data = res.data is String ? jsonDecode(res.data) : res.data;
      if (data is Map && data['display_name'] != null) {
        final displayName = data['display_name'].toString();
        final addr = data['address'] as Map?;
        final name = (addr?['road'] ?? addr?['suburb'] ?? displayName.split(',').first).toString();
        return PlaceSearchResult(
          name: name,
          displayName: displayName,
          latitude: lat,
          longitude: lng,
          city: addr?['city'] ?? addr?['town'] ?? addr?['county'],
          state: addr?['state'],
          sourceType: LocationSourceType.openStreetMap,
        );
      }
    } catch (_) {}

    // 3. Fallback to platform native geocoding
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
          sourceType: LocationSourceType.openStreetMap,
        );
      }
    } catch (_) {}

    // 4. Final coordinate fallback
    return PlaceSearchResult(
      name: 'Pinned Location',
      displayName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      latitude: lat,
      longitude: lng,
      sourceType: LocationSourceType.manualPin,
    );
  }
}
