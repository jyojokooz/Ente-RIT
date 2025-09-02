// lib/screens/admin/admin_manage_departments_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageDepartmentsScreen extends StatefulWidget {
  const AdminManageDepartmentsScreen({super.key});

  @override
  State<AdminManageDepartmentsScreen> createState() =>
      _AdminManageDepartmentsScreenState();
}

class _AdminManageDepartmentsScreenState
    extends State<AdminManageDepartmentsScreen> {
  Future<void> _showAddDepartmentDialog() async {
    final departmentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text('Add New Department'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: departmentController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., Computer Science',
              ),
              validator:
                  (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Please enter a department name.'
                          : null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  FirebaseFirestore.instance.collection('departments').add({
                    'name': departmentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDepartment(String docId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: const Text('Delete Department?'),
            content: const Text(
              'Are you sure? This won\'t remove it from existing user profiles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('departments')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Departments', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDepartmentDialog,
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('departments')
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.school_outlined,
                    color: Colors.yellow,
                  ),
                  title: Text(doc['name']),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteDepartment(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
