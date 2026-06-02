// ===============================
// FILE NAME: admin_manage_campus_videos_screen.dart
// FILE PATH: lib/screens/admin/admin_manage_campus_videos_screen.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class AdminManageCampusVideosScreen extends StatefulWidget {
  const AdminManageCampusVideosScreen({super.key});

  @override
  State<AdminManageCampusVideosScreen> createState() =>
      _AdminManageCampusVideosScreenState();
}

class _AdminManageCampusVideosScreenState
    extends State<AdminManageCampusVideosScreen> {
  Future<void> _showAddVideoSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();

    File? videoFile;
    File? thumbnailFile;
    bool isUploading = false;
    bool isPickingVideo = false;
    String uploadStatus = '';
    final ImagePicker picker = ImagePicker();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputColor = isDark ? const Color(0xFF0F0F13) : Colors.grey.shade100;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
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
                    'Add Campus Highlight Video',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
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
                            GestureDetector(
                              onTap:
                                  (isUploading || isPickingVideo)
                                      ? null
                                      : () async {
                                        setSheetState(() {
                                          isPickingVideo = true;
                                        });
                                        try {
                                          final XFile? video = await picker
                                              .pickVideo(
                                                source: ImageSource.gallery,
                                              );
                                          if (video != null) {
                                            setSheetState(() {
                                              uploadStatus =
                                                  'Generating thumbnail...';
                                            });
                                            final thumbFile =
                                                await VideoCompress.getFileThumbnail(
                                                  video.path,
                                                );
                                            setSheetState(() {
                                              videoFile = File(video.path);
                                              thumbnailFile = thumbFile;
                                              uploadStatus = '';
                                            });
                                          }
                                        } catch (e) {
                                          debugPrint("Image picker error: $e");
                                        } finally {
                                          if (mounted) {
                                            setSheetState(() {
                                              isPickingVideo = false;
                                            });
                                          }
                                        }
                                      },
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: inputColor,
                                  borderRadius: BorderRadius.circular(20),
                                  image:
                                      thumbnailFile != null
                                          ? DecorationImage(
                                            image: FileImage(thumbnailFile!),
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
                                    thumbnailFile == null
                                        ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.video_library_rounded,
                                              size: 40,
                                              color: const Color(0xFFFF3E8E),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              uploadStatus.isNotEmpty
                                                  ? uploadStatus
                                                  : "Tap to select Video",
                                              style: GoogleFonts.poppins(
                                                color: textColor.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Center(
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Video Title *",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: titleController,
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g., Tech Fest 2024 Highlights',
                                hintStyle: GoogleFonts.poppins(
                                  color: textColor.withOpacity(0.3),
                                ),
                                filled: true,
                                fillColor: inputColor,
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
                                  (v) =>
                                      v!.isEmpty ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 32),
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
                                              videoFile != null &&
                                              thumbnailFile != null) {
                                            setSheetState(() {
                                              isUploading = true;
                                              uploadStatus =
                                                  'Compressing video...';
                                            });

                                            try {
                                              // Compress video
                                              final MediaInfo? mediaInfo =
                                                  await VideoCompress.compressVideo(
                                                    videoFile!.path,
                                                    quality:
                                                        VideoQuality
                                                            .MediumQuality,
                                                    deleteOrigin: false,
                                                  );

                                              // THE FIX: Extracted file properly with null checks
                                              final File? compressedVideoFile =
                                                  mediaInfo?.file;

                                              if (compressedVideoFile == null) {
                                                throw Exception(
                                                  "Compression failed to return a file.",
                                                );
                                              }

                                              final cloudinary =
                                                  CloudinaryPublic(
                                                    cloudinaryCloudName,
                                                    cloudinaryUploadPreset,
                                                  );

                                              setSheetState(() {
                                                uploadStatus =
                                                    'Uploading thumbnail...';
                                              });

                                              // Upload thumbnail
                                              CloudinaryResponse thumbRes =
                                                  await cloudinary.uploadFile(
                                                    CloudinaryFile.fromFile(
                                                      thumbnailFile!.path,
                                                      folder:
                                                          'campus_highlights/thumbnails',
                                                    ),
                                                  );

                                              setSheetState(() {
                                                uploadStatus =
                                                    'Uploading video...';
                                              });

                                              // Upload video
                                              CloudinaryResponse videoRes =
                                                  await cloudinary.uploadFile(
                                                    CloudinaryFile.fromFile(
                                                      compressedVideoFile.path,
                                                      folder:
                                                          'campus_highlights/videos',
                                                      resourceType:
                                                          CloudinaryResourceType
                                                              .Video,
                                                    ),
                                                  );

                                              setSheetState(() {
                                                uploadStatus =
                                                    'Saving to database...';
                                              });

                                              // Save to Firestore
                                              await FirebaseFirestore.instance
                                                  .collection('campus_videos')
                                                  .add({
                                                    'title':
                                                        titleController.text
                                                            .trim(),
                                                    'videoUrl':
                                                        videoRes.secureUrl,
                                                    'thumbnailUrl':
                                                        thumbRes.secureUrl,
                                                    'createdAt':
                                                        FieldValue.serverTimestamp(),
                                                  });

                                              if (mounted)
                                                Navigator.pop(context);
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
                                                setSheetState(() {
                                                  isUploading = false;
                                                  uploadStatus = '';
                                                });
                                              }
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Please provide a title and select a video.",
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
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              uploadStatus,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          "Publish Highlight",
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

  Future<void> _deleteVideo(String docId) async {
    await FirebaseFirestore.instance
        .collection('campus_videos')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Manage Campus Videos',
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
        onPressed: _showAddVideoSheet,
        backgroundColor: const Color(0xFFFF3E8E),
        icon: const Icon(Icons.video_call_rounded, color: Colors.white),
        label: Text(
          "Add Video",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('campus_videos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_rounded,
                    size: 60,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No campus videos yet.",
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: data['thumbnailUrl'] ?? '',
                              width: 100,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder:
                                  (c, u) => Container(
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.grey.shade200,
                                  ),
                            ),
                            Container(
                              color: Colors.black38,
                              width: 100,
                              height: 70,
                            ),
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Video',
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteVideo(doc.id),
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
