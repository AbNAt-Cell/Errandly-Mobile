import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../services/location_search_service.dart';
import '../services/location_service.dart';

/// Modal dialog/sheet allowing users to search an address via autocomplete
/// or interactively drop a pin on an OpenStreetMap to select exact coordinates.
class LocationPickerSheet extends StatefulWidget {
  final String title;
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const LocationPickerSheet({
    super.key,
    required this.title,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  static Future<PlaceSearchResult?> show(
    BuildContext context, {
    required String title,
    double? initialLat,
    double? initialLng,
    String? initialAddress,
  }) {
    return showModalBottomSheet<PlaceSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerSheet(
        title: title,
        initialLat: initialLat,
        initialLng: initialLng,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late final MapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  late LatLng _currentCenter;
  String _resolvedAddress = '';
  bool _isResolving = false;
  bool _isSearching = false;
  List<PlaceSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(
      widget.initialLat ?? AppConstants.defaultLat,
      widget.initialLng ?? AppConstants.defaultLng,
    );
    _resolvedAddress = widget.initialAddress ?? '';

    if (_resolvedAddress.isEmpty) {
      _reverseGeocodeCenter();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await LocationSearchService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(PlaceSearchResult item) {
    setState(() {
      _currentCenter = LatLng(item.latitude, item.longitude);
      _resolvedAddress = item.displayName;
      _searchResults = [];
      _searchCtrl.text = item.displayName;
    });
    _mapController.move(_currentCenter, 16.0);
    FocusScope.of(context).unfocus();
  }

  Future<void> _reverseGeocodeCenter() async {
    setState(() => _isResolving = true);
    final place = await LocationSearchService.reverseGeocode(
      _currentCenter.latitude,
      _currentCenter.longitude,
    );
    if (mounted) {
      setState(() {
        _resolvedAddress = place?.displayName ?? '${_currentCenter.latitude}, ${_currentCenter.longitude}';
        _isResolving = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final target = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentCenter = target);
      _mapController.move(target, 16.0);
      _reverseGeocodeCenter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search street, building, landmark or city...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
              ),
            ),
          ),

          // Suggestions overlay if searching
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outlineVariant),
                itemBuilder: (ctx, idx) {
                  final item = _searchResults[idx];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(item.displayName, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectSearchResult(item),
                  );
                },
              ),
            ),

          // Map View with Center Pin
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 15.0,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && pos.center != null) {
                        _currentCenter = pos.center!;
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _reverseGeocodeCenter();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.errand.app',
                    ),
                  ],
                ),

                // Center Pin Icon
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Point here',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ),

                // Current location button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'loc_picker_gps',
                    onPressed: _useCurrentLocation,
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.primary,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),

          // Selected Address card & Confirm Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'SELECTED LOCATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_isResolving) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _resolvedAddress.isNotEmpty ? _resolvedAddress : 'Move the map to set exact location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          PlaceSearchResult(
                            name: _resolvedAddress.split(',').first,
                            displayName: _resolvedAddress,
                            latitude: _currentCenter.latitude,
                            longitude: _currentCenter.longitude,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Confirm Location Coordinates',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

