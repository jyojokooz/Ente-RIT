import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminViewCafeteriaOrdersScreen extends StatelessWidget {
  const AdminViewCafeteriaOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Food Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: const Center(
        child: Text(
          'Admin UI for Viewing User Orders',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
