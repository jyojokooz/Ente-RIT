import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- FIX: ADDED THIS IMPORT
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

  @override
  void initState() {
    super.initState();
    _locationRef = FirebaseDatabase.instance.ref(
      'live_locations/${_currentUser.uid}',
    );
  }

  @override
  void dispose() {
    _stopSharing();
    super.dispose();
  }

  Future<void> _toggleSharing() async {
    if (_isSharing) {
      _stopSharing();
    } else {
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

    setState(() => _isSharing = true);

    final initialLocation = await _location.getLocation();
    await _locationRef.set({
      'latitude': initialLocation.latitude,
      'longitude': initialLocation.longitude,
      'timestamp': ServerValue.timestamp,
      'driverName': driverName,
    });
    await _locationRef.onDisconnect().remove();

    _locationSubscription = _location.onLocationChanged.listen((
      LocationData currentLocation,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSharing ? Icons.local_shipping : Icons.bus_alert_outlined,
              size: 100,
              color: _isSharing ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              _isSharing ? 'Live Location is ON' : 'Live Location is OFF',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                backgroundColor: _isSharing ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: Text(_isSharing ? 'Stop Sharing' : 'Start Sharing'),
            ),
          ],
        ),
      ),
    );
  }
}
