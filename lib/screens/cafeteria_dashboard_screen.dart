import 'package:flutter/material.dart';
// --- THIS IS THE FIX ---
import 'package:google_fonts/google_fonts.dart';
// --- END OF FIX ---

// Import the screens that the cafeteria staff will manage
import 'admin/admin_manage_cafeteria_menu_screen.dart';
import 'cafeteria_admin_screen.dart';

class CafeteriaDashboardScreen extends StatelessWidget {
  const CafeteriaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Cafeteria Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildManagementCard(
            context: context,
            label: 'Manage Food Orders',
            subtitle: 'View and update status of all incoming orders',
            icon: Icons.receipt_long_outlined,
            color: Colors.orange,
            screen: const CafeteriaAdminScreen(),
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage Menu Items',
            subtitle: 'Add, edit, or remove items from the menu',
            icon: Icons.restaurant_menu_outlined,
            color: Colors.blueGrey,
            screen: const AdminManageCafeteriaMenuScreen(),
          ),
        ],
      ),
    );
  }

  // Helper widget for creating consistent navigation tiles
  Widget _buildManagementCard({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            ),
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }
}
