// ===============================
// FILE NAME: user_bus_tracking_screen.dart
// FILE PATH: lib/screens/user_bus_tracking_screen.dart
// ===============================

import 'dart:async';
import 'dart:ui';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Dynamic map tiles based on theme
    final mapUrl =
        isDark
            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    if (_busLocation != null && _isFirstLocationUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_busLocation!, 15.0);
          setState(() => _isFirstLocationUpdate = false);
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.routeDoc['routeName'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor:
            isDark
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _busLocation ??
                  const LatLng(9.5916, 76.5222), // RIT Coordinates fallback
              initialZoom: 15.0,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: mapUrl,
                userAgentPackageName: 'com.enterit.app',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: _buildCustomMarker(
                        Icons.person_rounded,
                        Colors.blueAccent,
                      ),
                    ),
                  if (_busLocation != null)
                    Marker(
                      point: _busLocation!,
                      width: 70,
                      height: 70,
                      child: _buildCustomMarker(
                        Icons.directions_bus_rounded,
                        const Color(0xFF30CFD0),
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
                ],
              ),
            ],
          ),

          // Loading Overlay if waiting for GPS
          if (_busLocation == null || _userLocation == null)
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.black54 : Colors.white54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252528) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF30CFD0),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Locating bus...",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Info Panel
          if (_distanceInKm != null && _timeToArriveInMinutes != null)
            _buildGlassInfoPanel(isDark),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: (_distanceInKm != null) ? 120.0 : 16.0,
        ), // Adjust FAB position above panel
        child: FloatingActionButton(
          onPressed: () {
            if (_userLocation != null) {
              _mapController.move(_userLocation!, 16.0);
            }
          },
          backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
          foregroundColor: const Color(0xFF30CFD0),
          elevation: 4,
          child: const Icon(Icons.my_location_rounded),
        ),
      ),
    );
  }

  Widget _buildCustomMarker(IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        // Map Pin Pointer Triangle
        Container(
          width: 0,
          height: 0,
          decoration: BoxDecoration(
            border: Border(
              left: const BorderSide(width: 6, color: Colors.transparent),
              right: const BorderSide(width: 6, color: Colors.transparent),
              top: BorderSide(width: 8, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInfoPanel(bool isDark) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  icon: Icons.route_rounded,
                  value: '${_distanceInKm!.toStringAsFixed(1)} km',
                  label: 'Distance Left',
                  color: const Color(0xFF30CFD0),
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                _buildInfoColumn(
                  icon: Icons.timer_rounded,
                  value: '$_timeToArriveInMinutes min',
                  label: 'Est. Arrival',
                  color: const Color(0xFFFF9A44),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
