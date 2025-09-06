import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// --- NEW: Imports needed to fetch user data ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/marketplace_service.dart';
import 'chat_list_screen.dart';
import 'create_listing_screen.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  String? _selectedCategory;

  // --- NEW: State variables for user's profile photo ---
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

  // --- NEW: Fetch user data when the screen initializes ---
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfilePhoto = false);
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!['profilePhotoUrl'] != null) {
        if (mounted) {
          setState(() {
            _currentUserProfilePhotoUrl = doc.data()!['profilePhotoUrl'];
            _isLoadingProfilePhoto = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingProfilePhoto = false);
        }
      }
    } catch (e) {
      // Handle potential errors
      if (mounted) {
        setState(() => _isLoadingProfilePhoto = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    // Also refresh the user profile on pull-to-refresh
    _loadUserProfile();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: Text(
          "Student Market",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.amber.shade600,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          // --- UPDATED: AppBar action to show the user's photo ---
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: _buildProfileAvatar(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingScreen()),
          );
        },
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.black,
        tooltip: 'Sell Item',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.black,
        backgroundColor: Colors.amber.shade700,
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

  // --- NEW: Helper widget to build the profile avatar with loading/fallback ---
  Widget _buildProfileAvatar() {
    if (_isLoadingProfilePhoto) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_currentUserProfilePhotoUrl != null &&
        _currentUserProfilePhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(_currentUserProfilePhotoUrl!),
        backgroundColor: Colors.grey.shade800,
      );
    }

    // Fallback icon if no photo is available
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 22, color: Colors.white),
    );
  }

  // ... (rest of the file remains exactly the same)

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG9otby1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color.fromRGBO(0, 0, 0, 0.5),
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
        color: Colors.white,
        fontSize: 20,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search for anything...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 90,
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
                if (categoryName == 'All') {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = categoryName;
                }
              });
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.amber.shade700
                            : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    category['icon'],
                    color: isSelected ? Colors.black : Colors.amber.shade600,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  categoryName,
                  style: TextStyle(
                    color: isSelected ? Colors.amber.shade600 : Colors.white70,
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
            child: CircularProgressIndicator(color: Colors.amber),
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
                    .where((product) => product.category == _selectedCategory)
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
      locale: 'en_US',
      symbol: '\$',
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
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
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currencyFormatter.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.amber.shade600,
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
