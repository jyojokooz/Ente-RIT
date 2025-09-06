import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  // --- NEW: State variable to track the selected category ---
  // `null` will represent the "All" category.
  String? _selectedCategory;

  // --- UPDATED: Added an "All" category at the beginning ---
  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Textbooks', 'icon': Icons.menu_book_outlined},
    {'name': 'Electronics', 'icon': Icons.laptop_chromebook_outlined},
    {'name': 'Lab & Gear', 'icon': Icons.science_outlined},
    {'name': 'Dorm Supplies', 'icon': Icons.lightbulb_outline},
    {'name': 'Gaming', 'icon': Icons.sports_esports_outlined},
  ];

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
          const SizedBox(width: 10),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSectionHeader("Categories"),
              const SizedBox(height: 12),
              _buildCategoryList(),
              const SizedBox(height: 24),
              _buildSectionHeader("Listings"), // Renamed for clarity
              const SizedBox(height: 12),
              _buildProductGrid(),
            ],
          ),
        ),
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

          // --- NEW: Logic to determine if a category is selected ---
          final bool isSelected =
              (_selectedCategory == null && categoryName == 'All') ||
              (_selectedCategory == categoryName);

          return GestureDetector(
            // --- NEW: onTap to update the state ---
            onTap: () {
              setState(() {
                if (categoryName == 'All') {
                  _selectedCategory = null; // Clear the filter
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
                  // --- NEW: Visual feedback for selected category ---
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
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            "No items for sale yet.\nBe the first to list something!",
          );
        }

        final allProducts = snapshot.data!;

        // --- NEW: Filtering logic happens here ---
        final filteredProducts =
            _selectedCategory == null
                ? allProducts // If no category is selected, show all
                : allProducts
                    .where((product) => product.category == _selectedCategory)
                    .toList();

        // --- NEW: Show message if filter results are empty ---
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
          itemCount: filteredProducts.length, // Use the filtered list
          itemBuilder: (context, index) {
            final product = filteredProducts[index]; // Use the filtered list
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

  // --- NEW: Helper widget for empty states ---
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
