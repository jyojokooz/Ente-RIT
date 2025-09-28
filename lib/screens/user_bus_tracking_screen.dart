import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class UserBusTrackingScreen extends StatefulWidget {
  final DocumentSnapshot routeDoc;
  const UserBusTrackingScreen({super.key, required this.routeDoc});

  @override
  State<UserBusTrackingScreen> createState() => _UserBusTrackingScreenState();
}

class _UserBusTrackingScreenState extends State<UserBusTrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<DatabaseEvent>? _busLocationSubscription;
  StreamSubscription<LocationData>? _userLocationSubscription;

  final Location _location = Location();

  LatLng? _busLocation;
  LatLng? _userLocation;

  double? _distanceInKm;
  int? _timeToArriveInMinutes;

  bool _isFirstLocationUpdate = true;

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
    _startListeningForBus();
  }

  @override
  void dispose() {
    _busLocationSubscription?.cancel();
    _userLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserLocation() async {
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

    _userLocationSubscription = _location.onLocationChanged.listen((
      currentLocation,
    ) {
      if (mounted &&
          currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _userLocation = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
          _calculateDistanceAndTime();
        });
      }
    });
  }

  void _startListeningForBus() {
    final driverId = widget.routeDoc['driverId'];
    if (driverId == null) return;

    final locationRef = FirebaseDatabase.instance.ref(
      'live_locations/$driverId',
    );
    _busLocationSubscription = locationRef.onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _busLocation = LatLng(data['latitude'], data['longitude']);
          _calculateDistanceAndTime();
        });
      } else if (mounted) {
        setState(() => _busLocation = null);
      }
    });
  }

  void _calculateDistanceAndTime() {
    if (_userLocation == null || _busLocation == null) return;

    const distanceCalculator = Distance();
    final distanceInMeters = distanceCalculator(_busLocation!, _userLocation!);
    final distanceInKm = distanceInMeters / 1000;

    const averageBusSpeedKmh = 20.0;
    final timeInHours = distanceInKm / averageBusSpeedKmh;
    final timeInMinutes = (timeInHours * 60).round();

    setState(() {
      _distanceInKm = distanceInKm;
      _timeToArriveInMinutes = timeInMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_busLocation != null && _isFirstLocationUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_busLocation!, 15.0);
          setState(() {
            _isFirstLocationUpdate = false;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeDoc['routeName'], style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busLocation ?? const LatLng(9.5916, 76.5222),
              initialZoom: 15.0,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.my_project',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  if (_busLocation != null)
                    Marker(
                      point: _busLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.cyanAccent,
                        size: 40,
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap:
                        () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                  ),
                  TextSourceAttribution(
                    'CARTO',
                    onTap:
                        () => launchUrl(
                          Uri.parse('https://carto.com/attributions'),
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (_busLocation == null || _userLocation == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Waiting for location data..."),
                ],
              ),
            ),
          if (_distanceInKm != null && _timeToArriveInMinutes != null)
            _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // --- THIS IS THE FIX ---
          // Replaced deprecated .withOpacity(0.7) with .withAlpha(178)
          color: Colors.black.withAlpha(178), // 255 * 0.7 = 178.5
          // --- END OF FIX ---
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoColumn(
              icon: Icons.social_distance,
              value: '${_distanceInKm!.toStringAsFixed(1)} km',
              label: 'Distance Left',
            ),
            _buildInfoColumn(
              icon: Icons.timer_outlined,
              value: '~ $_timeToArriveInMinutes min',
              label: 'Est. Arrival',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
