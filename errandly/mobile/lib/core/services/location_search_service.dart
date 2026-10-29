import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class PlaceSearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;

  const PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
  });

  @override
  String toString() => displayName;
}

/// Service that resolves real-world place search autocomplete queries
/// and reverse-geocodes coordinates into precise street addresses.
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
  static Future<List<PlaceSearchResult>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final results = <PlaceSearchResult>[];

    // 1. Try Photon (OpenStreetMap based, high speed, worldwide)
    try {
      final res = await _dio.get(
        'https://photon.komoot.io/api/',
        queryParameters: {
          'q': cleanQuery,
          'limit': 8,
          // Bias slightly towards Nigeria / West Africa default center
          'lat': 6.5244,
          'lon': 3.3792,
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
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('LocationSearchService Photon error: $e');
    }

    if (results.isNotEmpty) return results;

    // 2. Fallback to OpenStreetMap Nominatim search
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
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('LocationSearchService Nominatim fallback error: $e');
    }

    return results;
  }

  /// Reverse geocode coordinates (lat, lng) into a structured place result.
  static Future<PlaceSearchResult?> reverseGeocode(double lat, double lng) async {
    // 1. Try Nominatim Reverse
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
        );
      }
    } catch (_) {}

    // 2. Fallback to platform native geocoding
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
        );
      }
    } catch (_) {}

    return PlaceSearchResult(
      name: 'Pinned Location',
      displayName: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      latitude: lat,
      longitude: lng,
    );
  }
}

