import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- THIS IS THE CORRECTED IMPORT BLOCK ---
import '../services/marketplace_service.dart';
import 'product_detail_screen.dart';
// The ProductCard is defined in marketplace_screen.dart, so we import it.
import 'marketplace_screen.dart';
// --- END OF CORRECTIONS ---

class MarketplaceMyAdsScreen extends StatelessWidget {
  const MarketplaceMyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MarketplaceService marketplaceService = MarketplaceService();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Handle the case where the user might not be logged in
    if (currentUser == null) {
      return const Center(child: Text("Please log in to see your ads."));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'My Listings',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Product>>(
        // Use the new service function to get products for the current user
        stream: marketplaceService.getProductsForUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final products = snapshot.data!;

          // We reuse the GridView from the home page for a consistent look
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                // We reuse the same ProductCard widget
                child: ProductCard(product: product),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for the empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'You haven\'t listed any items yet.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to sell something!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
