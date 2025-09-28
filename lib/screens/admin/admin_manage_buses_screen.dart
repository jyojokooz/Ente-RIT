import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageBusesScreen extends StatefulWidget {
  const AdminManageBusesScreen({super.key});
  @override
  State<AdminManageBusesScreen> createState() => _AdminManageBusesScreenState();
}

class _AdminManageBusesScreenState extends State<AdminManageBusesScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _showAddOrEditDialog({DocumentSnapshot? route}) async {
    final routeNameController = TextEditingController(
      text: route?['routeName'],
    );
    final busNumberController = TextEditingController(
      text: route?['busNumber'],
    );
    String? selectedDriverId = route?['driverId'];

    // Fetch all users with the 'driver' role
    final driversSnapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .get();
    final drivers = driversSnapshot.docs;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(route == null ? 'Add New Route' : 'Edit Route'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: routeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Route Name (e.g., Route A)',
                      ),
                    ),
                    TextField(
                      controller: busNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Bus Number',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      hint: const Text('Assign Driver'),
                      onChanged:
                          (value) =>
                              setDialogState(() => selectedDriverId = value),
                      items:
                          drivers.map((driverDoc) {
                            final driver = driverDoc.data();
                            return DropdownMenuItem(
                              value: driverDoc.id,
                              child: Text(
                                driver['displayName'] ?? driverDoc.id,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (routeNameController.text.isNotEmpty &&
                        busNumberController.text.isNotEmpty &&
                        selectedDriverId != null) {
                      final data = {
                        'routeName': routeNameController.text,
                        'busNumber': busNumberController.text,
                        'driverId': selectedDriverId,
                      };
                      if (route == null) {
                        await _firestore.collection('bus_routes').add(data);
                      } else {
                        await route.reference.update(data);
                      }
                      // ignore: use_build_context_synchronously
                      if (mounted) Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bus Routes', style: GoogleFonts.poppins()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOrEditDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bus_routes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(doc['routeName']),
                subtitle: Text('Bus: ${doc['busNumber']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddOrEditDialog(route: doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
