// ===============================
// FILE NAME: marketplace_service.dart
// FILE PATH: lib/services/marketplace_service.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- PRODUCTS ---

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
    final dataWithSoldStatus = {...productData, 'isSold': false};
    await _productsCollection.add(dataWithSoldStatus);
  }

  Future<void> markAsSold(String productId) async {
    await _productsCollection.doc(productId).update({'isSold': true});
  }

  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }

  // --- WISHLIST LOGIC ---

  Future<void> toggleWishlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // Check if item is already in wishlist
    final doc = await userRef.get();
    final List<dynamic> wishlist = doc.data()?['wishlist'] ?? [];

    if (wishlist.contains(productId)) {
      await userRef.update({
        'wishlist': FieldValue.arrayRemove([productId]),
      });
    } else {
      await userRef.update({
        'wishlist': FieldValue.arrayUnion([productId]),
      });
    }
  }

  Stream<List<String>> getWishlistStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || !data.containsKey('wishlist')) return [];
          return List<String>.from(data['wishlist']);
        });
  }
}
