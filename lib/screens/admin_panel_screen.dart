import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<void> _toggleUserRole(String userId, String currentRole) async {
    final newRole = currentRole == 'driver' ? 'user' : 'driver';
    final bool confirmChange =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: Colors.grey.shade800,
                title: const Text('Change Role?'),
                content: Text(
                  'Do you want to change this user\'s role to "$newRole"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmChange) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
    }
  }

  Future<void> _deletePost(String postId) async {
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: const Text('Delete Post?'),
            content: const Text('Are you sure you want to delete this post?'),
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

  Future<void> _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    File? eventImageFile;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    // Capture the context BEFORE the dialog is shown.
    final dialogContext = context;

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade800,
              title: const Text('Add New Event'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap:
                            isUploading
                                ? null
                                : () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null) {
                                    setDialogState(
                                      () => eventImageFile = File(image.path),
                                    );
                                  }
                                },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(12),
                            image:
                                eventImageFile != null
                                    ? DecorationImage(
                                      image: FileImage(eventImageFile!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              eventImageFile == null
                                  ? const Center(
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : DateFormat.yMMMMd().format(selectedDate!),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setDialogState(() => selectedDate = pickedDate);
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : selectedTime!.format(context),
                        ),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setDialogState(() => selectedTime = pickedTime);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                            if (formKey.currentState!.validate() &&
                                selectedDate != null &&
                                selectedTime != null &&
                                eventImageFile != null) {
                              final navigator = Navigator.of(dialogContext);
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                dialogContext,
                              );

                              setDialogState(() => isUploading = true);

                              try {
                                final cloudinary = CloudinaryPublic(
                                  cloudinaryCloudName,
                                  cloudinaryUploadPreset,
                                );
                                CloudinaryResponse response = await cloudinary
                                    .uploadFile(
                                      CloudinaryFile.fromFile(
                                        eventImageFile!.path,
                                        folder: 'events',
                                      ),
                                    );
                                final imageUrl = response.secureUrl;
                                final eventTimestamp = Timestamp.fromDate(
                                  DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                    selectedTime!.hour,
                                    selectedTime!.minute,
                                  ),
                                );
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .add({
                                      'title': titleController.text.trim(),
                                      'description':
                                          descriptionController.text.trim(),
                                      'eventDate': eventTimestamp,
                                      'imageUrl': imageUrl,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                navigator.pop();
                              } catch (e) {
                                if (scaffoldMessenger.mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Failed to create event: $e",
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (formKey.currentContext != null) {
                                  setDialogState(() => isUploading = false);
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please fill all fields, including the image.",
                                  ),
                                ),
                              );
                            }
                          },
                  child:
                      isUploading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Add Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection('events').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Admin Panel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.grey.shade900,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.yellow,
            tabs: [
              Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
              Tab(icon: Icon(Icons.school_outlined), text: 'Departments'),
              Tab(icon: Icon(Icons.event_outlined), text: 'Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostsView(),
            _buildUsersView(),
            _buildDepartmentsView(),
            _buildEventsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('events')
                .orderBy('eventDate', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events found. Add one!'));
          }

          final events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;
              final eventDate =
                  (eventData['eventDate'] as Timestamp?)?.toDate();

              return ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.yellow),
                title: Text(eventData['title'] ?? 'No Title'),
                subtitle: Text(
                  eventDate != null
                      ? DateFormat(
                        'EEE, MMM d, yyyy • h:mm a',
                      ).format(eventDate)
                      : 'No date',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteEvent(event.id),
                ),
              );
            },
          );
        },
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
            final String role = userData['role'] ?? 'user';
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (role == 'driver')
                    const Chip(
                      label: Text('Driver'),
                      backgroundColor: Colors.cyan,
                      labelStyle: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  if (isAdmin)
                    const Chip(
                      label: Text('Admin'),
                      backgroundColor: Colors.yellow,
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  if (!isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'toggle_role') {
                          _toggleUserRole(user.id, role);
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'toggle_role',
                              child: Text(
                                role == 'driver'
                                    ? 'Set as User'
                                    : 'Set as Driver',
                              ),
                            ),
                          ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
