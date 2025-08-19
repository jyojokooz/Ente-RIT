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
      sellerPhotoUrl:
          data['sellerPhotoUrl'] ??
          'https://i.pravatar.cc/150', // A generic placeholder
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class MarketplaceService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // --- PRODUCT FUNCTIONS ---

  /// Retrieves a real-time stream of all product listings, ordered by the newest first.
  Stream<List<Product>> getProductsStream() {
    return _productsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  /// Adds a new product document to the 'products' collection in Firestore.
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _productsCollection.add(productData);
  }
}
