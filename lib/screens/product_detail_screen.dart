import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/marketplace_service.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  bool _isDeleting = false;

  Future<void> _deleteListing() async {
    setState(() => _isDeleting = true);
    try {
      await _marketplaceService.deleteProduct(widget.product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Delete Listing?',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
            content: Text(
              'This action cannot be undone.',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _deleteListing();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSeller = currentUser?.uid == widget.product.sellerId;

    // --- NEW VIBRANT COLOR PALETTE ---
    const Color primaryRed = Color(0xFFE53935);
    const Color primaryGreen = Color(0xFF43A047);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 1,
                iconTheme: const IconThemeData(color: Colors.black),
                actions: [
                  if (isSeller)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: primaryRed),
                      onPressed: _showDeleteConfirmationDialog,
                      tooltip: 'Delete Listing',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag:
                        'product_image_${widget.product.id}', // For smooth transitions
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormatter.format(widget.product.price),
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "Description",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            widget.product.sellerPhotoUrl,
                          ),
                        ),
                        title: Text(
                          "Sold by ${widget.product.sellerName}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          "Posted on ${DateFormat.yMMMd().format(widget.product.timestamp.toDate())}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 100), // Extra space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withAlpha(
                180,
              ), // Use withAlpha for modern opacity
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Deleting listing...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed:
                isSeller
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                receiverId: widget.product.sellerId,
                                receiverName: widget.product.sellerName,
                                receiverImageUrl: widget.product.sellerPhotoUrl,
                              ),
                        ),
                      );
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isSeller ? Icons.person_outline : Icons.chat_bubble_outline,
            ),
            label: Text(
              isSeller ? "This is Your Listing" : "Contact Seller",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
