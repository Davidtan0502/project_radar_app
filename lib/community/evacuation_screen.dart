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

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location service disabled; stop loading so UI shows details.
        setState(() {
          _currentPosition = null;
          _loading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied; stop loading and continue without location.
          setState(() {
            _currentPosition = null;
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied; stop loading and continue without location.
        setState(() {
          _currentPosition = null;
          _loading = false;
        });
        return;
      }

      // If everything ok, get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _loading = false;
      });
    } catch (e) {
      // Any error: log and show content without location.
      debugPrint('Error obtaining location: $e');
      if (mounted) {
        setState(() {
          _currentPosition = null;
          _loading = false;
        });
      }
    }
  }

  // <-- Updated function: uses Uri.https with queryParameters for safe encoding -->
  Future<void> _openGoogleMaps() async {
    final destinationAddress = widget.address;

    Uri uri;
    if (_currentPosition != null) {
      final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      uri = Uri.https(
        'www.google.com',
        '/maps/dir/',
        {
          'api': '1',
          'origin': origin,
          'destination': destinationAddress,
          'travelmode': 'driving',
        },
      );
    } else {
      // No origin available — open Maps with destination only.
      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {
          'api': '1',
          'query': destinationAddress,
        },
      );
    }

    debugPrint('Opening maps URL: ${uri.toString()}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
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
                  const SizedBox(height: 12),

                  // If location unavailable, show brief hint (non-intrusive).
                  if (_currentPosition == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Location unavailable. "Get Directions" will open maps with the destination only.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),

                  const SizedBox(height: 8),
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
