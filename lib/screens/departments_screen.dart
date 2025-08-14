import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_card.dart'; // <-- Import the reusable card
import 'web_view_screen.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Departments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('departments')
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No departments found.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }
          final departments = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.0,
            ),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              final deptData = dept.data() as Map<String, dynamic>;
              final String departmentName = deptData['name'] ?? 'No Name';

              // --- USING THE REUSABLE WIDGET ---
              return CategoryCard(
                label: departmentName,
                icon: Icons.school_outlined,
                color: Colors.blue.shade400,
                cardColor: Colors.grey.shade900,
                textColor: Colors.white70,
                onTap: () {
                  if (departmentName.toLowerCase() == 'mca') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const WebViewScreen(
                              title: 'MCA Department',
                              url: 'https://techworldthink.github.io/MCA/',
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on $departmentName')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
