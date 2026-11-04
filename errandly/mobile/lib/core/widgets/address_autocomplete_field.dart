import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/location_search_service.dart';

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool required;
  final bool isVerified;
  final double? currentLat;
  final double? currentLng;
  final void Function(PlaceSearchResult place) onPlaceSelected;
  final VoidCallback onClear;
  final VoidCallback onPickOnMap;
  final VoidCallback onUseGps;
  final bool isGpsLoading;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText = 'Search street, landmark, or city...',
    this.prefixIcon = Icons.location_on_rounded,
    this.required = true,
    this.isVerified = false,
    this.currentLat,
    this.currentLng,
    required this.onPlaceSelected,
    required this.onClear,
    required this.onPickOnMap,
    required this.onUseGps,
    this.isGpsLoading = false,
    this.validator,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  Timer? _debounce;
  bool _isSearching = false;
  bool _isResolving = false;
  List<PlacePredictionItem> _predictions = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay removal slightly so tap on item registers
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    } else if (widget.controller.text.trim().length >= 2 && _predictions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _onTextChanged(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _predictions = [];
        _isSearching = false;
        _hasSearched = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    _showOverlay();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await LocationSearchService.autocomplete(
          query,
          biasLat: widget.currentLat,
          biasLng: widget.currentLng,
        );
        if (mounted) {
          setState(() {
            _predictions = results;
            _isSearching = false;
          });
          _overlayEntry?.markNeedsBuild();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
          _overlayEntry?.markNeedsBuild();
        }
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final renderBox = this.context.findRenderObject() as RenderBox?;
        final size = renderBox?.size ?? Size.zero;

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Location Suggestions',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          Text(
                            'Google Places',
                            style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Content
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                            SizedBox(width: 10),
                            Text('Searching Google Places...', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      )
                    else if (_predictions.isNotEmpty)
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _predictions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
                          itemBuilder: (context, index) {
                            final pred = _predictions[index];
                            return InkWell(
                              onTap: () => _handlePredictionSelected(pred),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pred.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (pred.secondaryText.isNotEmpty || pred.displayName != pred.name)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                pred.secondaryText.isNotEmpty ? pred.secondaryText : pred.displayName,
                                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (_hasSearched)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Text(
                          'No matching places found. Try a broader search or pick on map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _handlePredictionSelected(PlacePredictionItem pred) async {
    _removeOverlay();
    _focusNode.unfocus();

    setState(() => _isResolving = true);

    try {
      PlaceSearchResult? result;

      if (pred.latitude != null && pred.longitude != null) {
        result = PlaceSearchResult(
          name: pred.name,
          displayName: pred.displayName,
          latitude: pred.latitude!,
          longitude: pred.longitude!,
          placeId: pred.placeId,
          sourceType: pred.sourceType,
        );
      } else if (pred.placeId.isNotEmpty) {
        result = await LocationSearchService.fetchPlaceDetails(
          pred.placeId,
          defaultName: pred.name,
          defaultDisplay: pred.displayName,
        );
      }

      if (result != null) {
        widget.controller.text = result.displayName;
        widget.onPlaceSelected(result);
      } else {
        widget.controller.text = pred.displayName;
      }
    } catch (e) {
      debugPrint('Error selecting place: $e');
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input row with quick action icons
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            validator: widget.validator ??
                (v) => (v?.isEmpty ?? true) && widget.required ? '${widget.label} is required' : null,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: Icon(widget.prefixIcon, color: AppColors.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching || _isResolving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  else if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      tooltip: 'Clear',
                      onPressed: () {
                        widget.controller.clear();
                        _removeOverlay();
                        widget.onClear();
                      },
                    ),
                  IconButton(
                    icon: widget.isGpsLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.my_location_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Current GPS',
                    onPressed: widget.isGpsLoading ? null : widget.onUseGps,
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Pick on Map',
                    onPressed: widget.onPickOnMap,
                  ),
                ],
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.isVerified ? const Color(0xFF10B981) : colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          // Verified coordinates / status pill
          if (widget.isVerified && widget.currentLat != null && widget.currentLng != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Verified (${widget.currentLat!.toStringAsFixed(4)}, ${widget.currentLng!.toStringAsFixed(4)})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
