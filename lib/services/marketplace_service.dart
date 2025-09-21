// --- THIS IS THE FIX ---
// This import defines all the necessary Firestore classes like DocumentSnapshot,
// CollectionReference, Timestamp, and FirebaseFirestore.
import 'package:cloud_firestore/cloud_firestore.dart';
// --- END OF FIX ---

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
  final bool isSold;

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
    required this.isSold,
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
      isSold: data['isSold'] ?? false,
    );
  }
}

class MarketplaceService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  /// Fetches only UNSOLD products for the main feed
  Stream<List<Product>> getProductsStream() {
    return _productsCollection
        .where('isSold', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  /// Fetches UNSOLD products for a specific user ("My Ads")
  Stream<List<Product>> getProductsForUserStream(String userId) {
    return _productsCollection
        .where('sellerId', isEqualTo: userId)
        .where('isSold', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  /// Fetches a stream of SOLD products listed by a specific seller.
  Stream<List<Product>> getSoldProductsForUserStream(String userId) {
    return _productsCollection
        .where('sellerId', isEqualTo: userId)
        .where('isSold', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    // When adding a new product, ensure isSold is set to false
    final dataWithSoldStatus = {...productData, 'isSold': false};
    await _productsCollection.add(dataWithSoldStatus);
  }

  /// Marks a product as sold in the database.
  Future<void> markAsSold(String productId) async {
    await _productsCollection.doc(productId).update({'isSold': true});
  }

  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }
}
