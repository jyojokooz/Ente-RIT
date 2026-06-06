import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final User _currentUser = FirebaseAuth.instance.currentUser!;
  bool _pushEnabled = true;
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        final notifSettings =
            data['notificationSettings'] as Map<String, dynamic>? ?? {};
        setState(() {
          _pushEnabled = notifSettings['pushEnabled'] ?? true;
          _likesEnabled = notifSettings['likesEnabled'] ?? true;
          _commentsEnabled = notifSettings['commentsEnabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .set({
            'notificationSettings': {key: value},
          }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save setting: $e")));
    }
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
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            "Push Notifications",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            "Pause all notifications from Ente RIT",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          value: _pushEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFFF3E8E),
                          onChanged: (val) {
                            setState(() => _pushEnabled = val);
                            _updateSetting('pushEnabled', val);
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            "Likes",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            "Get notified when someone likes your post",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          value: _likesEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFFF3E8E),
                          onChanged:
                              !_pushEnabled
                                  ? null
                                  : (val) {
                                    setState(() => _likesEnabled = val);
                                    _updateSetting('likesEnabled', val);
                                  },
                        ),
                        Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            "Comments",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            "Get notified when someone comments",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          value: _commentsEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFFFF3E8E),
                          onChanged:
                              !_pushEnabled
                                  ? null
                                  : (val) {
                                    setState(() => _commentsEnabled = val);
                                    _updateSetting('commentsEnabled', val);
                                  },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
