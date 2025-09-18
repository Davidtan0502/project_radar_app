import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class EvacuationRouteScreen extends StatefulWidget {
  final String name;
  final double lat;
  final double lng;
  final Position currentPosition;

  const EvacuationRouteScreen({
    super.key,
    required this.name,
    required this.lat,
    required this.lng,
    required this.currentPosition,
  });

  @override
  State<EvacuationRouteScreen> createState() => _EvacuationRouteScreenState();
}

class _EvacuationRouteScreenState extends State<EvacuationRouteScreen> {
  late GoogleMapController _mapController;
  bool _isLoading = true;
  String _errorMessage = '';

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<String> _steps = [];

  static const String googleApiKey = "AIzaSyD72GRS8KWHU8yzaOX7qkolLP5uIW4P2Dk";

  @override
  void initState() {
    super.initState();
    _setupMapMarkers();
    _fetchRoute();
  }

  void _setupMapMarkers() {
    // Add current position marker
    _markers.add(
      Marker(
        markerId: const MarkerId("current_location"),
        position: LatLng(
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
        ),
        infoWindow: const InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add destination marker
    _markers.add(
      Marker(
        markerId: const MarkerId("destination"),
        position: LatLng(widget.lat, widget.lng),
        infoWindow: InfoWindow(title: widget.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _fetchRoute() async {
    final origin =
        "${widget.currentPosition.latitude},${widget.currentPosition.longitude}";
    final destination = "${widget.lat},${widget.lng}";

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["status"] != "OK" || data["routes"].isEmpty) {
        setState(() {
          _errorMessage = data["error_message"] ?? "No route found";
          _isLoading = false;
        });
        return;
      }

      final points = data["routes"][0]["overview_polyline"]["points"];
      final List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(points);

      final List<LatLng> polylineCoordinates = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Parse step-by-step directions
      final legs = data["routes"][0]["legs"][0];
      List<String> steps = [];
      for (var step in legs["steps"]) {
        final instruction = step["html_instructions"]
            .toString()
            .replaceAll(RegExp(r"<[^>]*>"), "");
        final distance = step["distance"]["text"];
        steps.add("$instruction ($distance)");
      }

      setState(() {
        _steps = steps;
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
        _isLoading = false;
      });

      // Animate camera to show the entire route
      if (polylineCoordinates.isNotEmpty) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList(polylineCoordinates),
            100,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch route: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDirectionsList() {
    if (_steps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading directions..."),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.directions, color: Colors.blue),
          title: Text(
            _steps[index],
            style: const TextStyle(fontSize: 14),
          ),
          contentPadding: EdgeInsets.zero,
          visualDensity: const VisualDensity(vertical: -2),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 16),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchRoute,
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Route to ${widget.name}"),
        backgroundColor: const Color(0xFF3F73A3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRoute,
            tooltip: 'Refresh route',
          ),
        ],
      ),
      body: _isLoading && _errorMessage.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : Column(
                  children: [
                    // Map (upper half)
                    Expanded(
                      flex: 2,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.lat, widget.lng),
                          zoom: 14,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        myLocationEnabled: true,
                        markers: _markers,
                        polylines: _polylines,
                      ),
                    ),
                    // Directions List (bottom half)
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.white,
                        child: _buildDirectionsList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}