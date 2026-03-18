// ===============================
// FILE NAME: driver_tracking_screen.dart
// FILE PATH: lib/screens/driver_tracking_screen.dart
// ===============================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});
  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with SingleTickerProviderStateMixin {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isSharing = false;
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late final DatabaseReference _locationRef;

  List<DocumentSnapshot> _assignedRoutes = [];
  DocumentSnapshot? _selectedRoute;
  bool _isLoadingRoutes = true;

  // Animation for the "Live" radar pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _locationRef = FirebaseDatabase.instance.ref(
      'live_locations/${_currentUser.uid}',
    );
    _fetchAssignedRoutes();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _stopSharing();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssignedRoutes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('bus_routes')
              .where('driverId', isEqualTo: _currentUser.uid)
              .get();
      if (mounted) {
        setState(() {
          _assignedRoutes = snapshot.docs;
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load routes: $e")));
      }
    }
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      _stopSharing();
    } else {
      if (_selectedRoute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a route first."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      await _startSharing();
    }
  }

  Future<void> _startSharing() async {
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

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();
    final driverName = userDoc.data()?['displayName'] ?? 'Driver';
    final busNumber = _selectedRoute!['busNumber'];
    final routeName = _selectedRoute!['routeName'];

    setState(() {
      _isSharing = true;
      _pulseController.repeat();
    });

    final initialLocation = await _location.getLocation();
    await _locationRef.set({
      'latitude': initialLocation.latitude,
      'longitude': initialLocation.longitude,
      'timestamp': ServerValue.timestamp,
      'driverName': driverName,
      'busNumber': busNumber,
      'routeName': routeName,
    });

    await _locationRef.onDisconnect().remove();

    _locationSubscription = _location.onLocationChanged.listen((
      currentLocation,
    ) {
      if (mounted && _isSharing) {
        _locationRef.update({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'timestamp': ServerValue.timestamp,
        });
      }
    });
  }

  void _stopSharing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationRef.remove();
    if (mounted) {
      setState(() {
        _isSharing = false;
        _pulseController.stop();
        _pulseController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Driver Console',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child:
            _isLoadingRoutes
                ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Route Selection
                      if (!_isSharing) ...[
                        Text(
                          'Select Active Route',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DocumentSnapshot>(
                              value: _selectedRoute,
                              hint: Text(
                                'Choose your current route',
                                style: TextStyle(color: subtitleColor),
                              ),
                              isExpanded: true,
                              dropdownColor: cardColor,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: subtitleColor,
                              ),
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              items:
                                  _assignedRoutes.map((route) {
                                    return DropdownMenuItem<DocumentSnapshot>(
                                      value: route,
                                      child: Text(
                                        "${route['routeName']} (Bus ${route['busNumber']})",
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedRoute = value),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Radar / Status Icon
                      Expanded(
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isSharing)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width:
                                          200 + (_pulseController.value * 100),
                                      height:
                                          200 + (_pulseController.value * 100),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(
                                          0xFF00C569,
                                        ).withOpacity(
                                          1 - _pulseController.value,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _isSharing
                                          ? const Color(0xFF00C569)
                                          : cardColor,
                                  boxShadow: [
                                    if (!isDark && !_isSharing)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    if (_isSharing)
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00C569,
                                        ).withOpacity(0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                  ],
                                ),
                                child: Icon(
                                  _isSharing
                                      ? Icons.satellite_alt_rounded
                                      : Icons.location_off_rounded,
                                  size: 60,
                                  color:
                                      _isSharing ? Colors.white : subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Status Text
                      Text(
                        _isSharing
                            ? 'Transmitting Location'
                            : 'Transmission Offline',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              _isSharing ? const Color(0xFF00C569) : textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSharing
                            ? 'Students can now track Bus ${_selectedRoute!['busNumber']} on ${String.fromCharCode(0x2022)} ${_selectedRoute!['routeName']}'
                            : 'Select a route and go online to share location.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Giant Action Button
                      Container(
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient:
                              _isSharing
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF3E8E),
                                      Color(0xFFFF0000),
                                    ],
                                  ) // Red Gradient
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFF00C6FB),
                                      Color(0xFF005BEA),
                                    ],
                                  ), // Blue Gradient
                          boxShadow: [
                            BoxShadow(
                              color: (_isSharing ? Colors.red : Colors.blue)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _toggleSharing,
                          icon: Icon(
                            _isSharing
                                ? Icons.power_settings_new_rounded
                                : Icons.wifi_tethering_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isSharing ? 'GO OFFLINE' : 'GO ONLINE',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }
}
