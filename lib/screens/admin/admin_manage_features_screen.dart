// ===============================
// FILE NAME: admin_manage_features_screen.dart
// FILE PATH: lib/screens/admin/admin_manage_features_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// IMPORT THE CONFIG WE JUST CREATED
import '../../config/feature_config.dart';

class AdminManageFeaturesScreen extends StatefulWidget {
  const AdminManageFeaturesScreen({super.key});

  @override
  State<AdminManageFeaturesScreen> createState() =>
      _AdminManageFeaturesScreenState();
}

class _AdminManageFeaturesScreenState extends State<AdminManageFeaturesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _ensureDbIsPopulated();
  }

  /// Checks the local config against Firestore. If a feature exists in code
  /// but not in DB, it adds it (defaulting to visible).
  Future<void> _ensureDbIsPopulated() async {
    setState(() => _isInitializing = true);
    final batch = _firestore.batch();
    bool needsCommit = false;

    try {
      final snapshot = await _firestore.collection('features').get();
      final existingIds = snapshot.docs.map((d) => d.id).toSet();

      // Loop through our code-defined features
      int index = 0;
      FeatureConfig.featureMap.forEach((key, value) {
        if (!existingIds.contains(key)) {
          final docRef = _firestore.collection('features').doc(key);
          batch.set(docRef, {
            'id': key,
            'label': value['label'],
            'isVisible': true, // Default to visible
            'order': index,
          });
          needsCommit = true;
        }
        index++;
      });

      if (needsCommit) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error initializing features DB: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _toggleFeature(String id, bool currentValue) async {
    await _firestore.collection('features').doc(id).update({
      'isVisible': !currentValue,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage App Features', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body:
          _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('features')
                        .orderBy('order')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String id = docs[index].id;
                      final bool isVisible = data['isVisible'] ?? false;

                      // Get styling from local config
                      final config = FeatureConfig.featureMap[id];

                      // If we have code for this feature, show it.
                      if (config != null) {
                        return Card(
                          color: Colors.grey.shade900,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SwitchListTile(
                            activeColor: Colors.green,
                            inactiveTrackColor: Colors.red.withAlpha(80),
                            title: Text(
                              config['label'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (config['color'] as Color).withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                config['icon'],
                                color: config['color'],
                              ),
                            ),
                            value: isVisible,
                            onChanged: (val) => _toggleFeature(id, isVisible),
                          ),
                        );
                      } else {
                        // Obsolete feature in DB but removed from code
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
    );
  }
}
