import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Keep this for map style
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:share_plus/share_plus.dart'; // Keep this for the share button

class StudentMapViewScreen extends StatefulWidget {
  const StudentMapViewScreen({super.key});

  @override
  State<StudentMapViewScreen> createState() => _StudentMapViewScreenState();
}

class _StudentMapViewScreenState extends State<StudentMapViewScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  // Linter Fix: The top-level _locationsRef is no longer needed as it's defined in the listen method.
  final Location _location = Location();

  Set<Marker> _markers = {};
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _listenToLocations();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
    // Linter Fix: No need to call the deprecated setMapStyle here.
  }

  void _listenToLocations() {
    // We define the ref here where it's used.
    final DatabaseReference locationsRef = FirebaseDatabase.instance.ref(
      'live_locations',
    );

    locationsRef.onValue.listen((DatabaseEvent event) {
      // Linter Fix: Use curly braces for the if statement.
      if (!mounted) {
        return;
      }

      if (event.snapshot.exists && event.snapshot.value != null) {
        final allLocations = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        final Set<Marker> updatedMarkers = {};

        allLocations.forEach((uid, data) {
          final locationData = Map<String, dynamic>.from(data);
          final lat = locationData['latitude'];
          final lng = locationData['longitude'];
          final driverName = locationData['driverName'] ?? 'Bus';
          if (lat != null && lng != null) {
            final marker = Marker(
              markerId: MarkerId(uid),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow,
              ),
              infoWindow: InfoWindow(
                title: driverName,
                snippet: 'Tap to share location',
                onTap: () {
                  final url =
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                  Share.share('Here is the current bus location: $url');
                },
              ),
            );
            updatedMarkers.add(marker);
          }
        });
        setState(() {
          _markers = updatedMarkers;
        });
      } else {
        setState(() {
          _markers = {};
        });
      }
    });
  }

  Future<void> _goToMe() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final LocationData locationData = await _location.getLocation();
    final LatLng myLocation = LatLng(
      locationData.latitude!,
      locationData.longitude!,
    );

    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: myLocation, zoom: 15.5, tilt: 50.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus Tracking', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        child: FloatingActionButton(
          onPressed: _goToMe,
          backgroundColor: Colors.yellow,
          child: const Icon(Icons.my_location, color: Colors.black),
        ),
      ),
      body: GoogleMap(
        // Linter Fix: Pass the style directly to the constructor.
        style: _mapStyle,
        initialCameraPosition: const CameraPosition(
          target: LatLng(9.9312, 76.2673),
          zoom: 12,
        ),
        onMapCreated: (GoogleMapController controller) {
          // Linter Fix: The deprecated setMapStyle call is removed from here.
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
        markers: _markers,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
      ),
    );
  }
}
