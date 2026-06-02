import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminManageEventsScreen extends StatefulWidget {
  const AdminManageEventsScreen({super.key});

  @override
  State<AdminManageEventsScreen> createState() =>
      _AdminManageEventsScreenState();
}

class _AdminManageEventsScreenState extends State<AdminManageEventsScreen> {
  // --- MODERN BOTTOM SHEET TO ADD EVENT ---
  Future<void> _showAddEventSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final whatsappController = TextEditingController();
    final bookingController = TextEditingController();

    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();
    File? eventImageFile;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputColor = isDark ? const Color(0xFF161618) : Colors.grey.shade100;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Create New Event',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Picker
                            GestureDetector(
                              onTap:
                                  isUploading
                                      ? null
                                      : () async {
                                        final XFile? image = await picker
                                            .pickImage(
                                              source: ImageSource.gallery,
                                            );
                                        if (image != null) {
                                          setSheetState(
                                            () =>
                                                eventImageFile = File(
                                                  image.path,
                                                ),
                                          );
                                        }
                                      },
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: inputColor,
                                  borderRadius: BorderRadius.circular(20),
                                  image:
                                      eventImageFile != null
                                          ? DecorationImage(
                                            image: FileImage(eventImageFile!),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                  ),
                                ),
                                child:
                                    eventImageFile == null
                                        ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_rounded,
                                              size: 40,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Upload Event Poster",
                                              style: GoogleFonts.poppins(
                                                color: textColor.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildInputLabel("Event Title *", textColor),
                            _buildTextField(
                              titleController,
                              'e.g., Tech Symposium 2024',
                              inputColor,
                              textColor,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),
                            _buildInputLabel("Description *", textColor),
                            _buildTextField(
                              descriptionController,
                              'Details about the event...',
                              inputColor,
                              textColor,
                              maxLines: 4,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            selectedDate ?? DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedDate != null) {
                                        setSheetState(
                                          () => selectedDate = pickedDate,
                                        );
                                      }
                                    },
                                    child: _buildPickerBox(
                                      Icons.calendar_month_rounded,
                                      selectedDate == null
                                          ? 'Date'
                                          : DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(selectedDate!),
                                      inputColor,
                                      textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedTime ?? TimeOfDay.now(),
                                      );
                                      if (pickedTime != null) {
                                        setSheetState(
                                          () => selectedTime = pickedTime,
                                        );
                                      }
                                    },
                                    child: _buildPickerBox(
                                      Icons.access_time_rounded,
                                      selectedTime == null
                                          ? 'Time'
                                          : selectedTime!.format(context),
                                      inputColor,
                                      textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            _buildInputLabel("WhatsApp Group Link", textColor),
                            _buildTextField(
                              whatsappController,
                              'https://chat.whatsapp.com/...',
                              inputColor,
                              textColor,
                              icon: Icons.link_rounded,
                            ),

                            const SizedBox(height: 16),
                            _buildInputLabel(
                              "Booking/Registration Link",
                              textColor,
                            ),
                            _buildTextField(
                              bookingController,
                              'https://forms.gle/...',
                              inputColor,
                              textColor,
                              icon: Icons.confirmation_number_outlined,
                            ),

                            const SizedBox(height: 32),

                            // Submit Button
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF3E8E),
                                    Color(0xFFFF9A44),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    isUploading
                                        ? null
                                        : () async {
                                          if (formKey.currentState!
                                                  .validate() &&
                                              selectedDate != null &&
                                              selectedTime != null &&
                                              eventImageFile != null) {
                                            setSheetState(
                                              () => isUploading = true,
                                            );

                                            try {
                                              // Upload image to Firebase Storage
                                              final fileName =
                                                  '${DateTime.now().millisecondsSinceEpoch}_${eventImageFile!.path.split('/').last}';
                                              final ref = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child('events')
                                                  .child(fileName);
                                              await ref.putFile(
                                                eventImageFile!,
                                              );
                                              final downloadUrl =
                                                  await ref.getDownloadURL();

                                              final eventTimestamp =
                                                  Timestamp.fromDate(
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
                                                    'title':
                                                        titleController.text
                                                            .trim(),
                                                    'description':
                                                        descriptionController
                                                            .text
                                                            .trim(),
                                                    'whatsappLink':
                                                        whatsappController.text
                                                            .trim(),
                                                    'bookingLink':
                                                        bookingController.text
                                                            .trim(),
                                                    'eventDate': eventTimestamp,
                                                    'imageUrl': downloadUrl,
                                                    'createdAt':
                                                        FieldValue.serverTimestamp(),
                                                  });

                                              if (mounted) {
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text("Error: $e"),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setSheetState(
                                                  () => isUploading = false,
                                                );
                                              }
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Please fill all required fields and upload an image.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    isUploading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          "Publish Event",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color bgColor,
    Color textColor, {
    int maxLines = 1,
    bool isRequired = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.3)),
        prefixIcon:
            icon != null
                ? Icon(icon, color: textColor.withOpacity(0.5), size: 20)
                : null,
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator:
          isRequired
              ? (v) => v!.isEmpty ? 'This field is required' : null
              : null,
    );
  }

  Widget _buildPickerBox(
    IconData icon,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF3E8E), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- MANUAL NOTIFICATION TRIGGER ---
  Future<void> _triggerNotification(String eventTitle, String eventId) async {
    final messageController = TextEditingController(
      text: "Don't miss out! $eventTitle is starting soon.",
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Send Push Reminder",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "This will send a notification to all users.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF161618) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  "Broadcast",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3E8E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('notification_requests')
                      .add({
                        'title': "Event Reminder 📅",
                        'body': messageController.text.trim(),
                        'eventId': eventId,
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'pending',
                      });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification sent successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection('events').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Manage Events',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventSheet,
        backgroundColor: textColor,
        icon: Icon(Icons.add, color: bgColor),
        label: Text(
          "New Event",
          style: GoogleFonts.poppins(
            color: bgColor,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 60,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No events to manage.",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final eventDate = (data['eventDate'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            data['imageUrl'] != null
                                ? CachedNetworkImage(
                                  imageUrl: data['imageUrl'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 80,
                                  height: 80,
                                  color:
                                      isDark
                                          ? Colors.black26
                                          : Colors.grey.shade200,
                                  child: const Icon(Icons.event),
                                ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'],
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              eventDate != null
                                  ? DateFormat(
                                    'MMM dd, yyyy • h:mm a',
                                  ).format(eventDate)
                                  : '',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF9A44),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFFFF3E8E),
                            ),
                            tooltip: "Send Push Reminder",
                            onPressed:
                                () =>
                                    _triggerNotification(data['title'], doc.id),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => _deleteEvent(doc.id),
                          ),
                        ],
                      ),
                    ],
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
