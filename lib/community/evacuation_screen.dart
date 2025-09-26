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

  /// Opens directions in the most appropriate handler available:
  /// 1) Android native navigation intent (google.navigation:) — best for Android navigation
  /// 2) comgooglemaps:// scheme (Google Maps app) if installed
  /// 3) Web fallback -> https://www.google.com/maps/dir/
  Future<void> _openGoogleMaps() async {
    final destinationAddress = widget.address;

    // Encode destination for scheme URIs
    final String encodedDestination = Uri.encodeComponent(destinationAddress);
    String? origin;
    if (_currentPosition != null) {
      origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    }

    // 1) Android native navigation intent (google.navigation:)
    //    Example: google.navigation:q=place+name OR q=lat,lng
    //    This is typically handled by Google Maps on Android and starts navigation directly.
    final Uri androidNavUri = Uri.parse('google.navigation:q=$encodedDestination&mode=d');

    // 2) comgooglemaps scheme — tries Google Maps app (iOS/Android if available)
    final String appOriginParam = origin != null ? 'saddr=${Uri.encodeComponent(origin)}&' : '';
    final Uri gmapsAppUri = Uri.parse('comgooglemaps://?$appOriginParam' 'daddr=$encodedDestination&directionsmode=driving');

    // 3) Web fallback (Google Maps directions)
    //    Using queryParameters ensures proper encoding.
    final Map<String, String> webParams = origin != null
        ? {'api': '1', 'origin': origin, 'destination': destinationAddress, 'travelmode': 'driving'}
        : {'api': '1', 'destination': destinationAddress};
    final Uri webUri = Uri.https('www.google.com', '/maps/dir/', webParams);

    debugPrint('Attempting androidNavUri: $androidNavUri');
    debugPrint('Attempting gmapsAppUri: $gmapsAppUri');
    debugPrint('Attempting webUri: $webUri');

    try {
      // Try android navigation intent first (Android devices handle this best).
      if (await canLaunchUrl(androidNavUri)) {
        final launched = await launchUrl(androidNavUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('androidNavUri launch returned false; continuing to other options.');
      } else {
        debugPrint('androidNavUri not available on this device.');
      }
    } catch (e) {
      debugPrint('Error launching androidNavUri: $e');
    }

    try {
      // Try Google Maps app scheme (comgooglemaps://)
      if (await canLaunchUrl(gmapsAppUri)) {
        final launched = await launchUrl(gmapsAppUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('gmapsAppUri launch returned false; continuing to web fallback.');
      } else {
        debugPrint('gmapsAppUri not available on this device.');
      }
    } catch (e) {
      debugPrint('Error launching gmapsAppUri: $e');
    }

    try {
      // Web fallback: /maps/dir/
      if (await canLaunchUrl(webUri)) {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
        debugPrint('webUri launch returned false.');
      } else {
        debugPrint('webUri cannot be launched.');
      }
    } catch (e) {
      debugPrint('Error launching webUri: $e');
    }

    // Final fallback: search the address
    final Uri fallbackSearch = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': destinationAddress});
    try {
      if (await canLaunchUrl(fallbackSearch)) {
        await launchUrl(fallbackSearch, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Error launching fallbackSearch: $e');
    }

    // If all failed, notify user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
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
