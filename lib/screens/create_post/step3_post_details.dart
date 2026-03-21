// ===============================
// FILE PATH: lib/screens/create_post/step3_post_details.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../create_post_screen.dart'; // For PostType Enum
import 'create_post_connector.dart'; // The new connector managing our sub-components!

class Step3PostDetails extends StatelessWidget {
  final TextEditingController captionController;
  final PostType postType;
  final List<File> mediaFiles;
  final File? thumbnailFile;

  final String location;
  final List<String> taggedUsers;
  final bool disableComments;
  final Map<String, dynamic>? selectedMusic;

  final VoidCallback onBack;
  final VoidCallback onShare;
  final Function(String) onUpdateLocation;
  final Function(List<String>) onUpdateTags;
  final Function(bool) onUpdateSettings;
  final Function(Map<String, dynamic>?) onUpdateMusic;

  const Step3PostDetails({
    super.key,
    required this.captionController,
    required this.postType,
    required this.mediaFiles,
    this.thumbnailFile,
    required this.location,
    required this.taggedUsers,
    required this.disableComments,
    this.selectedMusic,
    required this.onBack,
    required this.onShare,
    required this.onUpdateLocation,
    required this.onUpdateTags,
    required this.onUpdateSettings,
    required this.onUpdateMusic,
  });

  void _showLocationDialog(BuildContext context) {
    TextEditingController locCtrl = TextEditingController(text: location);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Add Location',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: locCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'E.g., RIT Campus',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () {
                  onUpdateLocation(locCtrl.text.trim());
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );
  }

  void _showTaggingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: UserTaggingSheet(
              initialTags: taggedUsers,
              onSaveTags: (newTags) => onUpdateTags(newTags),
            ),
          ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  title: const Text(
                    'Disable Comments',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Hide the comment button on this post',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: Switch(
                    value: disableComments,
                    onChanged: (val) {
                      onUpdateSettings(val);
                      Navigator.pop(ctx);
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    "New Post",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onShare,
                  child: Text(
                    "Share",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              postType == PostType.video &&
                                      thumbnailFile != null
                                  ? Image.file(
                                    thumbnailFile!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.file(
                                    mediaFiles[0],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: captionController,
                            maxLines: 5,
                            minLines: 1,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: "Write a caption...",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade900, thickness: 1),

                  // TAGGING TILE
                  _buildDetailTile(
                    Icons.person_add_outlined,
                    taggedUsers.isEmpty
                        ? "Tag people"
                        : "${taggedUsers.length} Person tagged",
                    () => _showTaggingSheet(context),
                    titleColor:
                        taggedUsers.isNotEmpty
                            ? Colors.blueAccent
                            : Colors.white,
                  ),

                  // LOCATION TILE
                  _buildDetailTile(
                    Icons.location_on_outlined,
                    location.isEmpty ? "Add location" : location,
                    () => _showLocationDialog(context),
                    titleColor:
                        location.isNotEmpty ? Colors.blueAccent : Colors.white,
                  ),

                  // MUSIC TILE (ONLY SHOWN FOR IMAGES)
                  if (postType == PostType.image)
                    _buildDetailTile(
                      Icons.music_note_outlined,
                      selectedMusic != null
                          ? "${selectedMusic!['trackName']}"
                          : "Add music",
                      () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey.shade900,
                          isScrollControlled: true,
                          builder:
                              (ctx) => MusicSearchSheet(
                                onMusicSelected: onUpdateMusic,
                              ),
                        );
                      },
                      titleColor:
                          selectedMusic != null
                              ? Colors.blueAccent
                              : Colors.white,
                      trailing:
                          selectedMusic != null
                              ? GestureDetector(
                                onTap: () => onUpdateMusic(null),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              )
                              : null,
                    ),

                  Divider(color: Colors.grey.shade900, thickness: 1),

                  // SETTINGS TILE
                  _buildDetailTile(
                    Icons.settings,
                    disableComments ? "Comments Disabled" : "Advanced settings",
                    () => _showSettingsSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color titleColor = Colors.white,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(color: titleColor, fontSize: 15),
      ),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}
