import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EvacuationCentersScreen extends StatefulWidget {
  const EvacuationCentersScreen({super.key});

  @override
  State<EvacuationCentersScreen> createState() =>
      _EvacuationCentersScreenState();
}

class _EvacuationCentersScreenState extends State<EvacuationCentersScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  bool _locationReady = false;
  bool _isRefreshing = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _selectedCenter;
  String _selectedCenterName = "";
  bool _showRoute = false;
  String _distance = "";
  String _duration = "";

  static const List<Map<String, dynamic>> evacuationCenters = [
    {
      "name": "Evacuation Center A",
      "lat": 14.5995,
      "lng": 120.9842,
    },
    {
      "name": "Evacuation Center B",
      "lat": 14.6091,
      "lng": 121.0223,
    },
    {
      "name": "Evacuation Center C",
      "lat": 14.5547,
      "lng": 121.0244,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isRefreshing = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _locationReady = true;
        _isRefreshing = false;
      });
      _addMarkers();
    } catch (e) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to get location"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _addMarkers() {
    final markers = <Marker>{};
    
    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Add evacuation center markers
    for (var center in evacuationCenters) {
      final markerId = MarkerId(center["name"]);
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(center["lat"], center["lng"]),
          infoWindow: InfoWindow(title: center["name"]),
          onTap: () {
            _showCenterDetails(center);
          },
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _showCenterDetails(Map<String, dynamic> center) {
    setState(() {
      _selectedCenter = LatLng(center["lat"], center["lng"]);
      _selectedCenterName = center["name"];
    });
    
    // Animate camera to the selected center
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedCenter!, 14),
    );
    
    // Show a bottom sheet with center details and navigation options
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                center["name"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Latitude: ${center['lat']}"),
              Text("Longitude: ${center['lng']}"),
              if (_distance.isNotEmpty && _duration.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Distance: $_distance"),
                Text("Estimated time: $_duration"),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _getDirections(center["lat"], center["lng"]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F73A3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Show Route"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showRoute = false;
                          _polylines.clear();
                          _distance = "";
                          _duration = "";
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Clear Route"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getDirections(double destLat, double destLng) async {
    if (_currentPosition == null) return;
    
    try {
      final origin = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
      final destination = "$destLat,$destLng";
      
      // Note: You need to replace 'YOUR_API_KEY' with your actual Google Directions API key
      final apiKey = 'YOUR_API_KEY';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey'
      );
      
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        // Parse distance and duration
        final distance = data['routes'][0]['legs'][0]['distance']['text'];
        final duration = data['routes'][0]['legs'][0]['duration']['text'];
        
        // Decode polyline points
        final points = data['routes'][0]['overview_polyline']['points'];
        final List<LatLng> routeCoords = _decodePoly(points);
        
        // Create polyline
        final String polylineIdVal = 'polyline_${destLat}_${destLng}';
        final PolylineId polylineId = PolylineId(polylineIdVal);
        
        final Polyline polyline = Polyline(
          polylineId: polylineId,
          color: Colors.blue,
          points: routeCoords,
          width: 5,
        );
        
        setState(() {
          _polylines = {polyline};
          _showRoute = true;
          _distance = distance;
          _duration = duration;
        });
        
        // Adjust camera to show the entire route
        final bounds = _boundsFromLatLngList(routeCoords);
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to get directions"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // Decode polyline points from the Directions API
  List<LatLng> _decodePoly(String encoded) {
    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Calculate bounds from a list of LatLng points
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      southwest: LatLng(x0!, y0!),
      northeast: LatLng(x1!, y1!),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sidePadding = MediaQuery.of(context).size.width * 0.05;

    final mapHeight = screenHeight * 0.35;
    final sectionSpacing = screenHeight * 0.025;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF3F73A3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Evacuation Centers",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sectionSpacing),

                    // Map Container
                    Container(
                      height: mapHeight,
                      margin: EdgeInsets.symmetric(horizontal: sidePadding),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _locationReady
                            ? GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  zoom: 14,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                markers: _markers,
                                polylines: _polylines,
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFF3F73A3)),
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: sectionSpacing * 1.5),

                    // Route Information
                    if (_showRoute)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sidePadding),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Route to $_selectedCenterName",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("Distance: $_distance"),
                              Text("Estimated time: $_duration"),
                            ],
                          ),
                        ),
                      ),

                    if (_showRoute) SizedBox(height: sectionSpacing),

                    // Evacuation Centers List
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Centers",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...evacuationCenters.map((center) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: const Icon(Icons.location_on,
                                    color: Colors.redAccent),
                                title: Text(center["name"]),
                                subtitle: Text(
                                    "Lat: ${center['lat']}, Lng: ${center['lng']}"),
                                trailing: const Icon(Icons.directions,
                                    color: Colors.blue),
                                onTap: () => _showCenterDetails(center),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}