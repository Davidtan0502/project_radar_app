import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  Marker? _marker;
  final Color _primaryColor = const Color(0xFF2E72AD);

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  LatLng? _selectedLatLng;
  bool _isLoading = false;
  Timer? _addressTypingTimer;
  final FocusNode _addressFocusNode = FocusNode();
  bool _isManualAddressEdit = false;

  // For handling the draggable sheet position
  double _sheetHeight = 0.45;

  // Fallback location if initial or device location not available (Manila)
  static const LatLng _fallbackLatLng = LatLng(14.5995, 120.9842);

  // Guard that indicates map controller is ready for channel calls
  bool _mapReady = false;

  // NEW: suppression flag to avoid loops when setting address programmatically
  bool _suppressAddressController = false;

  @override
  void initState() {
    super.initState();

    // Initialize selected location safely (don't assume initial values are valid)
    _initSelectedLocation();

    // Add listener for manual address input
    _addressController.addListener(_handleAddressInput);
  }

  Future<void> _initSelectedLocation() async {
    // Try to use the provided initial coords if they look valid; otherwise try device location
    if (_looksLikeValidLatLng(widget.initialLat, widget.initialLng)) {
      _selectedLatLng = LatLng(widget.initialLat, widget.initialLng);
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition();
        _selectedLatLng = LatLng(pos.latitude, pos.longitude);
      } catch (e) {
        // fallback
        _selectedLatLng = _fallbackLatLng;
      }
    }

    // Make sure marker and address are in sync
    if (mounted) {
      _setMarker(_selectedLatLng!);
      // ensure address is set without triggering the listener loop
      await _updateAddressFromLatLng(_selectedLatLng!);
      if (mounted) setState(() {});
    }
  }

  void _handleAddressInput() {
    // Prevent reacting to programmatic updates
    if (_suppressAddressController) return;

    // Only trigger if user is manually editing (has focus)
    if (_addressFocusNode.hasFocus && !_isLoading) {
      _addressTypingTimer?.cancel();
      _addressTypingTimer = Timer(const Duration(milliseconds: 1500), () {
        if (_addressController.text.isNotEmpty) {
          _isManualAddressEdit = true;
          _updateLatLongFromAddress(_addressController.text);
        }
      });
    }
  }

  void _setMarker(LatLng pos) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId("selected_location"),
        position: pos,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onDragEnd: (newPos) {
          _selectedLatLng = newPos;
          _isManualAddressEdit = false;
          _updateAddressFromLatLng(newPos);
        },
      );
    });
  }

  Future<void> _updateAddressFromLatLng(LatLng pos) async {
    if (_isManualAddressEdit) return; // Don't update if user is manually editing

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        // Suppress listener while we update the controllers programmatically
        _suppressAddressController = true;

        _addressController.text = address;
        _barangayController.text = place.locality ?? '';
        _streetController.text = place.street ?? '';

        // Release suppression after a short delay to avoid immediate re-trigger
        Future.delayed(const Duration(milliseconds: 150), () {
          _suppressAddressController = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error fetching address details'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLatLongFromAddress(String address) async {
    if (address.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);

        // Use safe animate wrapper (checks controller state and catches errors)
        await _safeAnimateCamera(CameraUpdate.newLatLng(newLatLng));

        setState(() {
          _selectedLatLng = newLatLng;
          _setMarker(newLatLng);
        });

        // Update address details from new coordinates (this will suppress listener internally)
        await _updateAddressFromLatLng(newLatLng);
      }
    } catch (e) {
      debugPrint("Error updating location from address: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not find this address'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isManualAddressEdit = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(pos.latitude, pos.longitude);

      await _safeAnimateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: newLatLng, zoom: 16),
      ));

      if (!mounted) return;
      setState(() {
        _selectedLatLng = newLatLng;
        _setMarker(newLatLng);
      });

      await _updateAddressFromLatLng(newLatLng);
    } catch (e) {
      debugPrint("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error accessing your location'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLocation() {
    if (_selectedLatLng == null) return;

    Navigator.pop(context, {
      "lat": _selectedLatLng!.latitude,
      "lng": _selectedLatLng!.longitude,
      "address": _addressController.text,
      "barangay": _barangayController.text,
      "street": _streetController.text,
    });
  }

  // Adjust map padding when sheet is dragged
  // NOTE: older google_maps_flutter versions don't expose setPadding on the controller.
  // We keep this method as a no-op to avoid plugin errors — the GoogleMap widget already
  // sets bottom padding using the `padding` parameter during build.
  void _adjustMapPadding(double sheetHeight) {
    // Intentionally left empty to avoid calling APIs that may not be available
    // (e.g., GoogleMapController.setPadding). The map's padding is handled
    // directly in the GoogleMap widget build below.
  }

  // Safe wrapper for animateCamera: checks controller readiness and catches exceptions.
  // Includes a small retry to handle cases where the platform view isn't fully ready.
  Future<void> _safeAnimateCamera(CameraUpdate update) async {
    if (!mounted) return;
    if (_mapController == null || !_mapReady) {
      debugPrint('safeAnimateCamera skipped: controller null or map not ready');
      return;
    }

    const int maxAttempts = 2;
    int attempt = 0;
    while (attempt < maxAttempts && mounted) {
      try {
        attempt++;
        await _mapController!.animateCamera(update);
        // success, return
        return;
      } catch (e, st) {
        debugPrint('safeAnimateCamera attempt $attempt failed: $e\n$st');
        // If last attempt, swallow and return; otherwise wait briefly and retry.
        if (attempt >= maxAttempts) return;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  // Helper to validate lat/lng
  bool _looksLikeValidLatLng(double lat, double lng) {
    return lat.abs() <= 90 && lng.abs() <= 180 && !(lat == 0.0 && lng == 0.0);
  }

  @override
  void dispose() {
    _addressTypingTimer?.cancel();
    _addressController.removeListener(_handleAddressInput);
    _addressController.dispose();
    _addressFocusNode.dispose();

    // mark map not ready before disposing controller
    _mapReady = false;
    try {
      _mapController?.dispose();
    } catch (e) {
      // ignore controller dispose errors
      debugPrint('Error disposing map controller: $e');
    }
    _mapController = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Guard: ensure we have a lat/lng to avoid build-time null errors.
    final startLatLng = _selectedLatLng ?? _fallbackLatLng;

    final initialCameraPos = CameraPosition(
      target: startLatLng,
      zoom: 16,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: initialCameraPos,
            onMapCreated: (controller) async {
              _mapController = controller;
              _mapReady = true;

              // Ensure the camera centers to the selected location (if available)
              if (_selectedLatLng != null) {
                // use safe animate; don't await too long during map init
                _safeAnimateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _selectedLatLng!, zoom: 16),
                  ),
                );
              }
            },
            markers: _marker != null ? {_marker!} : {},
            onTap: (pos) {
              setState(() {
                _selectedLatLng = pos;
                _setMarker(pos);
                _isManualAddressEdit = false;
              });
              _updateAddressFromLatLng(pos);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            // Keep padding here — we adjust sheetHeight so the bottom UI doesn't hide the marker.
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: MediaQuery.of(context).size.height * _sheetHeight + 20,
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Location details bottom sheet style
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _sheetHeight = notification.extent;
                    _adjustMapPadding(_sheetHeight); // no-op intentionally
                  });
                  return true;
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black26,
                        offset: Offset(0, -4),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Adjust your location",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF2E72AD),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                          readOnly: _isLoading,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            suffixIcon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : null,
                            hintText: "Type an address or select on map",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Additional Address Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _barangayController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Barangay",
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _streetController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "No. / Building / Street / Zone",
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.home_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _confirmLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Confirm Location",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Floating button for GPS
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * _sheetHeight + 16,
          right: 16,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: _isLoading ? null : _goToCurrentLocation,
          child: Icon(Icons.my_location,
              color: _isLoading ? Colors.grey : _primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}
