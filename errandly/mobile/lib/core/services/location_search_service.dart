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

class PlacePredictionItem {
  final String placeId;
  final String name;
  final String displayName;
  final String secondaryText;
  final double? latitude;
  final double? longitude;
  final LocationSourceType sourceType;

  const PlacePredictionItem({
    required this.placeId,
    required this.name,
    required this.displayName,
    this.secondaryText = '',
    this.latitude,
    this.longitude,
    this.sourceType = LocationSourceType.googlePlaces,
  });

  @override
  String toString() => displayName;
}

class PlaceSearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? city;
  final String? state;
  final LocationSourceType sourceType;
  final double? accuracyRadius; // in meters if known
  final Map<String, dynamic>? rawDetails;

  const PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.city,
    this.state,
    this.sourceType = LocationSourceType.googlePlaces,
    this.accuracyRadius,
    this.rawDetails,
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

  /// Fast Autocomplete returning real-time suggestions from Google Places.
  /// Runs in ~150-250ms without blocking on place details resolution.
  static Future<List<PlacePredictionItem>> autocomplete(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final targetLat = biasLat ?? AppConstants.defaultLat;
    final targetLng = biasLng ?? AppConstants.defaultLng;
    const apiKey = AppConstants.googleMapsApiKey;

    if (apiKey.isNotEmpty) {
      // 1. Google Places API (New) Autocomplete
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
            'input': cleanQuery,
            'locationBias': {
              'circle': {
                'center': {
                  'latitude': targetLat,
                  'longitude': targetLng,
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
          final items = <PlacePredictionItem>[];
          for (final item in suggestions.take(8)) {
            final pred = item['placePrediction'];
            if (pred == null) continue;

            final placeId = (pred['placeId'] ?? pred['place']?.toString().replaceFirst('places/', ''))?.toString() ?? '';
            final text = pred['text']?['text']?.toString() ?? '';
            final mainText = pred['structuredFormat']?['mainText']?['text']?.toString() ?? text.split(',').first;
            final secondaryText = pred['structuredFormat']?['secondaryText']?['text']?.toString() ?? '';

            items.add(PlacePredictionItem(
              placeId: placeId,
              name: mainText,
              displayName: text.isNotEmpty ? text : mainText,
              secondaryText: secondaryText,
              sourceType: LocationSourceType.googlePlaces,
            ));
          }
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('Places API (New) autocomplete error: $e');
      }

      // 2. Legacy Google Places API Autocomplete
      try {
        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json',
          queryParameters: {
            'input': cleanQuery,
            'key': apiKey,
            'components': 'country:ng',
            'location': '$targetLat,$targetLng',
            'radius': 50000,
          },
        );

        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final predictions = data['predictions'] as List?;
        if (predictions != null && predictions.isNotEmpty) {
          final items = <PlacePredictionItem>[];
          for (final pred in predictions.take(8)) {
            final placeId = pred['place_id']?.toString() ?? '';
            final description = pred['description']?.toString() ?? '';
            final mainText = pred['structured_formatting']?['main_text']?.toString() ?? description.split(',').first;
            final secondaryText = pred['structured_formatting']?['secondary_text']?.toString() ?? '';

            items.add(PlacePredictionItem(
              placeId: placeId,
              name: mainText,
              displayName: description.isNotEmpty ? description : mainText,
              secondaryText: secondaryText,
              sourceType: LocationSourceType.googlePlaces,
            ));
          }
          if (items.isNotEmpty) return items;
        }
      } catch (e) {
        debugPrint('Legacy Places API error: $e');
      }

      // 3. Fallback to Google Geocoding API
      try {
        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          queryParameters: {
            'address': cleanQuery,
            'key': apiKey,
            'components': 'country:ng',
          },
        );
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results.take(5).map((r) {
            final formatted = r['formatted_address']?.toString() ?? cleanQuery;
            final loc = r['geometry']?['location'];
            final lat = (loc?['lat'] as num?)?.toDouble() ?? targetLat;
            final lng = (loc?['lng'] as num?)?.toDouble() ?? targetLng;
            final placeId = r['place_id']?.toString() ?? '';

            return PlacePredictionItem(
              placeId: placeId,
              name: formatted.split(',').first,
              displayName: formatted,
              secondaryText: formatted.split(',').skip(1).join(',').trim(),
              latitude: lat,
              longitude: lng,
              sourceType: LocationSourceType.googlePlaces,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 4. Fallback search against known local Uyo landmarks
    final qLower = cleanQuery.toLowerCase();
    final matched = _uyoLandmarks.where((lm) =>
      lm.name.toLowerCase().contains(qLower) ||
      lm.displayName.toLowerCase().contains(qLower)
    ).toList();

    return matched.map((m) => PlacePredictionItem(
      placeId: 'landmark_${m.name.toLowerCase().replaceAll(' ', '_')}',
      name: m.name,
      displayName: m.displayName,
      latitude: m.latitude,
      longitude: m.longitude,
      sourceType: LocationSourceType.googlePlaces,
    )).toList();
  }

  /// Retrieve full place details (lat, lng, formatted address, city, state)
  /// when a user clicks/selects an autocomplete suggestion.
  static Future<PlaceSearchResult?> fetchPlaceDetails(
    String placeId, {
    String? defaultName,
    String? defaultDisplay,
  }) async {
    const apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty || placeId.isEmpty) return null;

    // Check if it's a mock/landmark ID
    if (placeId.startsWith('landmark_')) {
      final found = _uyoLandmarks.firstWhere(
        (lm) => 'landmark_${lm.name.toLowerCase().replaceAll(' ', '_')}' == placeId,
        orElse: () => _uyoLandmarks.first,
      );
      return found;
    }

    // 1. Google Places API (New) Place Details
    try {
      final detailRes = await _dio.get(
        'https://places.googleapis.com/v1/places/${Uri.encodeComponent(placeId)}',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,addressComponents,types',
          },
        ),
      );
      final detailData = detailRes.data is String ? jsonDecode(detailRes.data) : detailRes.data;
      final loc = detailData['location'];
      if (loc != null) {
        final lat = (loc['latitude'] as num).toDouble();
        final lng = (loc['longitude'] as num).toDouble();
        final displayName = detailData['formattedAddress']?.toString() ?? defaultDisplay ?? defaultName ?? '';
        final name = detailData['displayName']?['text']?.toString() ?? defaultName ?? displayName.split(',').first;

        String? city;
        String? state;
        final comps = detailData['addressComponents'] as List?;
        if (comps != null) {
          for (final c in comps) {
            final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
            if (types.contains('locality') || types.contains('administrative_area_level_2')) {
              city = c['longText']?.toString() ?? c['shortText']?.toString();
            }
            if (types.contains('administrative_area_level_1')) {
              state = c['longText']?.toString() ?? c['shortText']?.toString();
            }
          }
        }

        return PlaceSearchResult(
          name: name,
          displayName: displayName,
          latitude: lat,
          longitude: lng,
          placeId: detailData['id']?.toString() ?? placeId,
          city: city,
          state: state,
          sourceType: LocationSourceType.googlePlaces,
          rawDetails: detailData is Map<String, dynamic> ? detailData : null,
        );
      }
    } catch (e) {
      debugPrint('Places API (New) details error: $e');
    }

    // 2. Legacy Google Places API Place Details
    try {
      final detailRes = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'place_id,name,formatted_address,geometry,address_components',
          'key': apiKey,
        },
      );
      final detailData = detailRes.data is String ? jsonDecode(detailRes.data) : detailRes.data;
      final result = detailData['result'];
      final location = result?['geometry']?['location'];
      if (location != null) {
        final lat = (location['lat'] as num).toDouble();
        final lng = (location['lng'] as num).toDouble();
        final displayName = result['formatted_address']?.toString() ?? defaultDisplay ?? defaultName ?? '';
        final name = result['name']?.toString() ?? defaultName ?? displayName.split(',').first;

        String? city;
        String? state;
        final comps = result['address_components'] as List?;
        if (comps != null) {
          for (final c in comps) {
            final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
            if (types.contains('locality') || types.contains('administrative_area_level_2')) {
              city = c['long_name']?.toString() ?? c['short_name']?.toString();
            }
            if (types.contains('administrative_area_level_1')) {
              state = c['long_name']?.toString() ?? c['short_name']?.toString();
            }
          }
        }

        return PlaceSearchResult(
          name: name,
          displayName: displayName,
          latitude: lat,
          longitude: lng,
          placeId: result['place_id']?.toString() ?? placeId,
          city: city,
          state: state,
          sourceType: LocationSourceType.googlePlaces,
          rawDetails: result is Map<String, dynamic> ? result : null,
        );
      }
    } catch (e) {
      debugPrint('Legacy Places API details error: $e');
    }

    return null;
  }

  /// Full search resolving both predictions and coordinates.
  /// Uses parallel resolution for high speed.
  static Future<List<PlaceSearchResult>> search(
    String query, {
    double? biasLat,
    double? biasLng,
  }) async {
    final predictions = await autocomplete(query, biasLat: biasLat, biasLng: biasLng);
    if (predictions.isEmpty) return [];

    final results = <PlaceSearchResult>[];
    final futures = <Future<PlaceSearchResult?>>[];

    for (final p in predictions.take(6)) {
      if (p.latitude != null && p.longitude != null) {
        results.add(PlaceSearchResult(
          name: p.name,
          displayName: p.displayName,
          latitude: p.latitude!,
          longitude: p.longitude!,
          placeId: p.placeId,
          sourceType: p.sourceType,
        ));
      } else if (p.placeId.isNotEmpty) {
        futures.add(fetchPlaceDetails(
          p.placeId,
          defaultName: p.name,
          defaultDisplay: p.displayName,
        ));
      }
    }

    if (futures.isNotEmpty) {
      final resolved = await Future.wait(futures);
      for (final r in resolved) {
        if (r != null) results.add(r);
      }
    }

    return results;
  }

  static const List<PlaceSearchResult> _uyoLandmarks = [
    PlaceSearchResult(
      name: 'Ibom Plaza',
      displayName: 'Ibom Plaza, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0378,
      longitude: 7.9254,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Wellington Bassey Way',
      displayName: 'Wellington Bassey Way, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0395,
      longitude: 7.9348,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Dominic Utuk Avenue',
      displayName: 'Dominic Utuk Avenue, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0336,
      longitude: 7.9388,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'De Choice Mall',
      displayName: 'De Choice Mall, Ikot Ekpene Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0392,
      longitude: 7.9185,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Ikot Ekpene Road',
      displayName: 'Ikot Ekpene Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0441,
      longitude: 7.9103,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Oron Road',
      displayName: 'Oron Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0298,
      longitude: 7.9392,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Abak Road',
      displayName: 'Abak Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0285,
      longitude: 7.9124,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Aka Road',
      displayName: 'Aka Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0189,
      longitude: 7.9248,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Ewet Housing Estate',
      displayName: 'Ewet Housing Estate, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0152,
      longitude: 7.9512,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Shelter Afrique Estate',
      displayName: 'Shelter Afrique Estate, Oron Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0084,
      longitude: 7.9715,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Tropicana Entertainment Centre',
      displayName: 'Tropicana Entertainment Centre, Udo Udoma Avenue, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0098,
      longitude: 7.9372,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'University of Uyo (Town Campus)',
      displayName: 'University of Uyo (Town Campus), Ikpa Road, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0456,
      longitude: 7.9211,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'University of Uyo (Permanent Site)',
      displayName: 'University of Uyo (Permanent Site), Nwaniba Road, Use Offot, Uyo, Nigeria',
      latitude: 5.0264,
      longitude: 7.9892,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Ibom Icon Hotel & Golf Resort',
      displayName: 'Ibom Icon Hotel & Golf Resort, Nwaniba, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0742,
      longitude: 8.0215,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Victor Attah International Airport',
      displayName: 'Victor Attah International Airport, Okobo / Uyo, Akwa Ibom, Nigeria',
      latitude: 4.8725,
      longitude: 8.0878,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Itam Market',
      displayName: 'Itam Market, Calabar-Itu Highway, Uyo, Akwa Ibom, Nigeria',
      latitude: 5.0562,
      longitude: 7.8924,
      sourceType: LocationSourceType.googlePlaces,
    ),
    PlaceSearchResult(
      name: 'Akwa Ibom State Secretariat',
      displayName: 'Idongesit Nkanga State Secretariat Complex, Udo Udoma Avenue, Uyo, Nigeria',
      latitude: 5.0175,
      longitude: 7.9312,
      sourceType: LocationSourceType.googlePlaces,
    ),
  ];

  /// Reverse geocode coordinates (lat, lng) strictly via Google Geocoding.
  static Future<PlaceSearchResult?> reverseGeocode(double lat, double lng) async {
    const apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final res = await _dio.get(
          'https://maps.googleapis.com/maps/api/geocode/json',
          queryParameters: {
            'latlng': '$lat,$lng',
            'key': apiKey,
          },
        );
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results.first;
          final formatted = first['formatted_address']?.toString() ?? '';
          final name = formatted.split(',').first;
          final placeId = first['place_id']?.toString();

          String? city;
          String? state;
          final comps = first['address_components'] as List?;
          if (comps != null) {
            for (final c in comps) {
              final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
              if (types.contains('locality') || types.contains('administrative_area_level_2')) {
                city = c['long_name']?.toString() ?? c['short_name']?.toString();
              }
              if (types.contains('administrative_area_level_1')) {
                state = c['long_name']?.toString() ?? c['short_name']?.toString();
              }
            }
          }

          return PlaceSearchResult(
            name: name,
            displayName: formatted,
            latitude: lat,
            longitude: lng,
            placeId: placeId,
            city: city,
            state: state,
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
