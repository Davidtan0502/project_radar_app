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

  @override
  void initState() {
    super.initState();
    _selectedLatLng = LatLng(widget.initialLat, widget.initialLng);
    _setMarker(_selectedLatLng!);
    _updateAddressFromLatLng(_selectedLatLng!);
    
    // Add listener for manual address input
    _addressController.addListener(_handleAddressInput);
  }

  void _handleAddressInput() {
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
    
    setState(() => _isLoading = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        // Temporarily remove listener to prevent loop
        _addressController.removeListener(_handleAddressInput);
        
        _addressController.text = address;
        _barangayController.text = place.locality ?? '';
        _streetController.text = place.street ?? '';
        
        // Re-add listener after a delay
        Future.delayed(const Duration(milliseconds: 100), () {
          _addressController.addListener(_handleAddressInput);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLatLongFromAddress(String address) async {
    if (address.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);
        
        await _mapController?.animateCamera(
          CameraUpdate.newLatLng(newLatLng),
        );
        
        setState(() {
          _selectedLatLng = newLatLng;
          _setMarker(newLatLng);
        });
        
        // Update address details from new coordinates
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
        setState(() => _isLoading = false);
        _isManualAddressEdit = false;
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(pos.latitude, pos.longitude);
      
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16),
        ),
      );
      
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
  void _adjustMapPadding(double sheetHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetPixelHeight = screenHeight * sheetHeight;
    
    if (_mapController != null) {
      // Adjust map padding to ensure marker remains visible
      final padding = EdgeInsets.only(bottom: sheetPixelHeight + 20);
      _mapController!.setMapStyle('[]');
    }
  }

  @override
  void dispose() {
    _addressTypingTimer?.cancel();
    _addressController.removeListener(_handleAddressInput);
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPos = CameraPosition(
      target: _selectedLatLng!,
      zoom: 16,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: initialCameraPos,
            onMapCreated: (controller) {
              _mapController = controller;
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
                    _adjustMapPadding(_sheetHeight);
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