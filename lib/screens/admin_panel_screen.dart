import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<void> _deletePost(String postId) async {
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: const Text('Delete Post?'),
            content: const Text(
              'Are you sure you want to delete this post and all its comments?',
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

    if (didRequestDelete == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a department name.';
                }
                return null;
              },
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
              'Are you sure? This will not remove the department from existing user profiles.',
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Admin Panel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.grey.shade900,
          bottom: const TabBar(
            indicatorColor: Colors.yellow,
            tabs: [
              Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
              Tab(icon: Icon(Icons.school_outlined), text: 'Departments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostsView(),
            _buildUsersView(),
            _buildDepartmentsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No departments found. Add one!'));
          }
          final departments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              final deptData = dept.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(deptData['name'] ?? 'Unnamed Department'),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteDepartment(dept.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostsView() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellow),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts found.'));
        }
        final posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>;
            final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
            return ListTile(
              leading:
                  postData['postImageUrl'] != null &&
                          postData['postImageUrl'].isNotEmpty
                      ? Image.network(
                        postData['postImageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                      : const Icon(Icons.image_not_supported),
              title: Text(postData['caption'] ?? 'No caption'),
              subtitle: Text(
                'by ${postData['userName']} • ${timestamp != null ? timeago.format(timestamp) : '...'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: () => _deletePost(post.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellow),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        final users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            final bool isAdmin = userData['isAdmin'] ?? false;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    userData['profilePhotoUrl'] != null &&
                            userData['profilePhotoUrl'].isNotEmpty
                        ? NetworkImage(userData['profilePhotoUrl'])
                        : null,
                child:
                    userData['profilePhotoUrl'] == null ||
                            userData['profilePhotoUrl'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
              ),
              title: Text(userData['displayName'] ?? 'No Name'),
              subtitle: Text(userData['email'] ?? 'No Email'),
              trailing:
                  isAdmin
                      ? const Chip(
                        label: Text('Admin'),
                        backgroundColor: Colors.yellow,
                        labelStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            );
          },
        );
      },
    );
  }
}
