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

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isSharing = false;
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late final DatabaseReference _locationRef;

  List<DocumentSnapshot> _assignedRoutes = [];
  DocumentSnapshot? _selectedRoute;
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _locationRef = FirebaseDatabase.instance.ref(
      'live_locations/${_currentUser.uid}',
    );
    _fetchAssignedRoutes();
  }

  @override
  void dispose() {
    _stopSharing();
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
          const SnackBar(content: Text("Please select a route first.")),
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

    setState(() => _isSharing = true);

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
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Mode', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child:
                _isLoadingRoutes
                    ? const CircularProgressIndicator()
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isSharing) ...[
                          Text(
                            'Select Your Route',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<DocumentSnapshot>(
                            value: _selectedRoute,
                            hint: const Text('Choose a route'),
                            isExpanded: true,
                            items:
                                _assignedRoutes.map((route) {
                                  return DropdownMenuItem<DocumentSnapshot>(
                                    value: route,
                                    child: Text(
                                      "${route['routeName']} (${route['busNumber']})",
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedRoute = value);
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        Icon(
                          _isSharing
                              ? Icons.local_shipping
                              : Icons.bus_alert_outlined,
                          size: 100,
                          color: _isSharing ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isSharing
                              ? 'Live Location is ON'
                              : 'Live Location is OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isSharing && _selectedRoute != null)
                          Text(
                            'Sharing for Route: ${_selectedRoute!['routeName']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        Text(
                          _isSharing
                              ? 'Students can now see you on the map.'
                              : 'Tap the button to start sharing.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _toggleSharing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSharing ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            _isSharing ? 'Stop Sharing' : 'Start Sharing',
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
