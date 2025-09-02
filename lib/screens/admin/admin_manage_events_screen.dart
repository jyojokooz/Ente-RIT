// lib/screens/admin/admin_manage_events_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class AdminManageEventsScreen extends StatefulWidget {
  const AdminManageEventsScreen({super.key});

  @override
  State<AdminManageEventsScreen> createState() =>
      _AdminManageEventsScreenState();
}

class _AdminManageEventsScreenState extends State<AdminManageEventsScreen> {
  // Method for adding a new event
  Future<void> _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    File? eventImageFile;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();
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

  // Method for deleting an event
  Future<void> _deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection('events').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Events', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('events')
                .orderBy('eventDate')
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
              final eventDate = (doc['eventDate'] as Timestamp?)?.toDate();
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.yellow,
                  ),
                  title: Text(doc['title']),
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
                    onPressed: () => _deleteEvent(doc.id),
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
