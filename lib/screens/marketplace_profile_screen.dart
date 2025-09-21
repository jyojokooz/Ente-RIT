import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import screens we need to navigate to
import 'edit_profile_screen.dart';
import 'marketplace_my_ads_screen.dart';

class MarketplaceProfileScreen extends StatefulWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  State<MarketplaceProfileScreen> createState() =>
      _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends State<MarketplaceProfileScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;

  // State variables to hold the user's data
  String _displayName = '';
  String _username = '';
  String _profilePhotoUrl = '';
  int _listingCount = 0;
  int _connectionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userDocFuture =
          FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      // Use .count() for an efficient way to get the number of documents
      final productCountFuture =
          FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: _currentUser.uid)
              .count()
              .get();

      final responses = await Future.wait([userDocFuture, productCountFuture]);

      final userDoc = responses[0] as DocumentSnapshot<Map<String, dynamic>>;
      final productCountSnapshot = responses[1] as AggregateQuerySnapshot;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _displayName = data['displayName'] ?? 'No Name';
        _username = data['username'] ?? 'username';
        _profilePhotoUrl = data['profilePhotoUrl'] ?? '';
        _connectionCount = (data['connections'] as List? ?? []).length;
        _listingCount = productCountSnapshot.count ?? 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth-gate',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                color: Colors.white,
                backgroundColor: Colors.red,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              _profilePhotoUrl.isNotEmpty
                  ? NetworkImage(_profilePhotoUrl)
                  : null,
          child:
              _profilePhotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
        ),
        const SizedBox(height: 16),
        Text(
          _displayName,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          '@$_username',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            'Listings',
            _listingCount.toString(),
            Colors.yellow.shade800,
          ),
          _buildStatColumn(
            'Connections',
            _connectionCount.toString(),
            Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              _loadUserData();
            },
          ),
          const Divider(height: 1),
          _buildActionButton(
            icon: Icons.inventory_2_outlined,
            label: 'View My Listings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MarketplaceMyAdsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      // --- THIS IS THE FIX ---
      // We explicitly set the text color to a dark shade to make it visible.
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.black87, // This makes the text readable
        ),
      ),
      // --- END OF FIX ---
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
