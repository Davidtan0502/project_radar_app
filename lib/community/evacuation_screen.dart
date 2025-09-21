import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EvacuationScreen extends StatefulWidget {
  final String name;
  final String address;

  const EvacuationScreen({super.key, required this.name, required this.address});

  @override
  State<EvacuationScreen> createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen> {
  Position? _currentPosition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _loading = false;
    });
  }

  Future<void> _openGoogleMaps() async {
    if (_currentPosition == null) return;

    final destination = Uri.encodeComponent(widget.address);
    final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: const Color(0xFF3F73A3),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.address, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.directions),
                    label: const Text("Get Directions"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F73A3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
