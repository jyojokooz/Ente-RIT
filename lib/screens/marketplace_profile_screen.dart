import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A placeholder screen for the user's profile within the marketplace.
class MarketplaceProfileScreen extends StatelessWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_pin, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Marketplace profile coming soon!',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}