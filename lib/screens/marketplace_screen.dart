import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/marketplace_service.dart';
import 'chat_list_screen.dart'; // Already imported, now will be a main page
import 'create_listing_screen.dart';
import 'product_detail_screen.dart';
import 'marketplace_my_ads_screen.dart';
import 'marketplace_profile_screen.dart';

/// The main host screen with the Bottom Navigation Bar for the marketplace.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _currentIndex = 0;

  // --- CHANGE 1: ADD ChatListScreen to the list of pages ---
  final List<Widget> _pages = [
    const MarketplaceHome(), // Index 0
    const ChatListScreen(), // Index 1 (NEW)
    const MarketplaceMyAdsScreen(), // Index 2 (was 1)
    const MarketplaceProfileScreen(), // Index 3 (was 2)
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    const Color primaryYellow = Color(0xFFFFC107);
    const Color primaryGreen = Color(0xFF43A047);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingScreen()),
          );
        },
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        tooltip: 'Sell Item',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            // Use spaceBetween for a perfectly balanced 2x2 layout
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // --- CHANGE 2: RESTRUCTURE THE ROW FOR FOUR ITEMS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildNavItem(
                    Icons.storefront_outlined,
                    'Home',
                    0,
                    primaryYellow,
                  ),
                  _buildNavItem(
                    Icons.chat_bubble_outline,
                    'Chat',
                    1,
                    primaryGreen,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildNavItem(
                    Icons.inventory_2_outlined,
                    'My Ads',
                    2,
                    primaryYellow,
                  ),
                  _buildNavItem(
                    Icons.person_outline,
                    'Profile',
                    3,
                    primaryYellow,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build each icon-only navigation item.
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color activeColor,
  ) {
    final bool isSelected = _currentIndex == index;
    return IconButton(
      tooltip: label,
      icon: Icon(
        icon,
        color: isSelected ? activeColor : Colors.grey.shade600,
        size: 28,
      ),
      onPressed: () => _onTabTapped(index),
    );
  }
}

/// The home page widget containing the main product listings.
class MarketplaceHome extends StatefulWidget {
  const MarketplaceHome({super.key});

  @override
  State<MarketplaceHome> createState() => _MarketplaceHomeState();
}

class _MarketplaceHomeState extends State<MarketplaceHome> {
  // ... (State variables and methods like _loadUserProfile, _handleRefresh, etc. are unchanged)
  final MarketplaceService _marketplaceService = MarketplaceService();
  String? _selectedCategory;
  String? _currentUserProfilePhotoUrl;
  bool _isLoadingProfilePhoto = true;

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Textbooks', 'icon': Icons.menu_book_outlined},
    {'name': 'Electronics', 'icon': Icons.laptop_chromebook_outlined},
    {'name': 'Lab & Gear', 'icon': Icons.science_outlined},
    {'name': 'Dorm Supplies', 'icon': Icons.lightbulb_outline},
    {'name': 'Gaming', 'icon': Icons.sports_esports_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProfilePhoto = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data()?['profilePhotoUrl'] != null) {
        if (mounted) {
          setState(() {
            _currentUserProfilePhotoUrl = doc.data()!['profilePhotoUrl'];
            _isLoadingProfilePhoto = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingProfilePhoto = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfilePhoto = false);
    }
  }

  Future<void> _handleRefresh() async {
    _loadUserProfile();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Student Market",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        // --- CHANGE 3: REMOVE THE REDUNDANT CHAT ICON FROM APPBAR ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Simplified padding
            child: _buildProfileAvatar(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.white,
        backgroundColor: Colors.red.shade700,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildPromoBanner(),
                const SizedBox(height: 24),
                _buildSectionHeader("Categories"),
                const SizedBox(height: 12),
                _buildCategoryList(),
                const SizedBox(height: 24),
                _buildSectionHeader("Listings"),
                const SizedBox(height: 12),
                _buildProductGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // All the _build... methods below are unchanged and remain here.
  Widget _buildProfileAvatar() {
    if (_isLoadingProfilePhoto) {
      return CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade300);
    }
    if (_currentUserProfilePhotoUrl != null &&
        _currentUserProfilePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(_currentUserProfilePhotoUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade300,
      child: Icon(Icons.person, size: 22, color: Colors.grey.shade700),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1170',
          ),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Color.fromRGBO(0, 0, 0, 0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Find Your Next Deal",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Exclusive offers from students, for students.",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 20,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Search for anything...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.yellow.shade800, width: 2),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'];
          final bool isSelected =
              (_selectedCategory == null && categoryName == 'All') ||
              (_selectedCategory == categoryName);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory =
                    (categoryName == 'All') ? null : categoryName;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.yellow.shade700 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.yellow.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                            : [],
                  ),
                  child: Icon(
                    category['icon'],
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isSelected
                            ? Colors.yellow.shade800
                            : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Product>>(
      stream: _marketplaceService.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }
        if (snapshot.hasError) {
          return _buildEmptyState("Something went wrong. Pull to refresh.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            "No items for sale yet.\nBe the first to list something!",
          );
        }

        final allProducts = snapshot.data!;
        final filteredProducts =
            _selectedCategory == null
                ? allProducts
                : allProducts
                    .where((p) => p.category == _selectedCategory)
                    .toList();

        if (filteredProducts.isEmpty) {
          return _buildEmptyState("No items found in this category.");
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: ProductCard(product: product),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 18),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Hero(
              tag: 'product_image_${product.id}',
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currencyFormatter.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
