import 'package:cloud_firestore/cloud_firestore.dart';

// --- DATA MODEL for Product ---
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerPhotoUrl;
  final Timestamp timestamp;
  final String category;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhotoUrl,
    required this.timestamp,
    required this.category,
  });

  factory Product.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      sellerPhotoUrl: data['sellerPhotoUrl'] ?? 'https://i.pravatar.cc/150',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      category: data['category'] ?? 'Other',
    );
  }
}

class MarketplaceService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  Stream<List<Product>> getProductsStream() {
    return _productsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _productsCollection.add(productData);
  }

  // --- NEW: FUNCTION TO DELETE A PRODUCT ---
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
    // In a production app, you would also add logic here to delete
    // the associated image from Cloudinary using its API.
  }
}
