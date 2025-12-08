// ===============================
// FILE NAME: admin_manage_events_screen.dart
// FILE PATH: lib/screens/admin/admin_manage_events_screen.dart
// ===============================

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
  Future<void> _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    // --- NEW CONTROLLERS ---
    final whatsappController = TextEditingController();
    final bookingController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    File? eventImageFile;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    // We capture context before async gaps
    final parentContext = context;

    await showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: Text(
                'Add New Event',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Picker
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

                      // Text Fields
                      _buildTextField(
                        titleController,
                        'Event Title',
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        descriptionController,
                        'Description',
                        maxLines: 3,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      // --- NEW OPTIONAL FIELDS ---
                      _buildTextField(
                        whatsappController,
                        'WhatsApp Group Link (Optional)',
                        icon: Icons.chat,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        bookingController,
                        'Booking/Register Link (Optional)',
                        icon: Icons.link,
                      ),

                      const SizedBox(height: 20),

                      // Date & Time Pickers
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.date_range,
                          color: Colors.yellow,
                        ),
                        title: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : DateFormat.yMMMMd().format(selectedDate!),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null)
                            setDialogState(() => selectedDate = pickedDate);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.access_time,
                          color: Colors.yellow,
                        ),
                        title: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : selectedTime!.format(context),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null)
                            setDialogState(() => selectedTime = pickedTime);
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
                              setDialogState(() => isUploading = true);

                              try {
                                // Upload Image
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

                                final eventTimestamp = Timestamp.fromDate(
                                  DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                    selectedTime!.hour,
                                    selectedTime!.minute,
                                  ),
                                );

                                // Save to Firestore
                                await FirebaseFirestore.instance
                                    .collection('events')
                                    .add({
                                      'title': titleController.text.trim(),
                                      'description':
                                          descriptionController.text.trim(),
                                      'whatsappLink':
                                          whatsappController.text
                                              .trim(), // Save Link
                                      'bookingLink':
                                          bookingController.text
                                              .trim(), // Save Link
                                      'eventDate': eventTimestamp,
                                      'imageUrl': response.secureUrl,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                if (mounted) Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                if (mounted)
                                  setDialogState(() => isUploading = false);
                              }
                            } else {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please fill all required fields and image.",
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

  // Helper for fields
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isRequired = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white60) : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow),
        ),
      ),
      validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final eventDate = (data['eventDate'] as Timestamp?)?.toDate();

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading:
                      data['imageUrl'] != null
                          ? Image.network(
                            data['imageUrl'],
                            width: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.event),
                  title: Text(
                    data['title'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventDate != null
                            ? DateFormat.yMMMMd().add_jm().format(eventDate)
                            : '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (data['whatsappLink'] != null &&
                          data['whatsappLink'].toString().isNotEmpty)
                        const Text(
                          "WhatsApp Link Added",
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                    ],
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
