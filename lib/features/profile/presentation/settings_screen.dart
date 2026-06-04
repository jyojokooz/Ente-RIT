// ===============================
// FILE NAME: settings_screen.dart
// FILE PATH: lib/features/profile/presentation/settings_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_project/core/constants/theme_provider.dart';
import 'package:my_project/features/profile/presentation/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isPrivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyStatus();
  }

  Future<void> _loadPrivacyStatus() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      if (mounted && doc.exists) {
        setState(() {
          _isPrivate = doc.data()?['isPrivate'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrivacy(bool isPrivate) async {
    setState(() => _isPrivate = isPrivate); // Optimistic UI update

    try {
      // 1. Update User Profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({'isPrivate': isPrivate});

      // 2. Update all of the user's posts to reflect privacy status
      final postsQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser.uid)
              .get();

      if (postsQuery.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in postsQuery.docs) {
          batch.update(doc.reference, {'isAuthorPrivate': isPrivate});
        }
        await batch.commit();
      }
    } catch (e) {
      // Revert if failed
      setState(() => _isPrivate = !isPrivate);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update privacy: $e")));
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth-gate',
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  "Delete Account?",
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              "This action is permanent and cannot be undone. All your posts, connections, and data will be erased forever.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Delete Forever",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
        );

        await _currentUser.delete();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/auth-gate',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Remove loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Security requirement: Please log out and log back in to verify your identity before deleting.",
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
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
                child: CircularProgressIndicator(color: Color(0xFF673AB7)),
              )
              : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // --- ACCOUNT SECTION ---
                  _buildSectionTitle("Account", textColor),
                  _buildSettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    children: [
                      _buildListTile(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF00C6FB),
                        title: "Edit Profile",
                        subtitle: "Update your name, bio, and links",
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            ),
                      ),
                      _buildDivider(isDark),
                      _buildListTile(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF43E97B),
                        title: "Personal Information",
                        subtitle: "Email, phone number, and security",
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PersonalInfoScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- PREFERENCES SECTION ---
                  _buildSectionTitle("Preferences", textColor),
                  AnimatedBuilder(
                    animation: themeProvider,
                    builder: (context, _) {
                      return _buildSettingsGroup(
                        cardColor: cardColor,
                        isDark: isDark,
                        children: [
                          _buildSwitchTile(
                            icon:
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                            iconColor: const Color(0xFF673AB7),
                            title: "Dark Mode",
                            subtitle: "Switch between light and dark themes",
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            value: themeProvider.isDarkMode,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                          ),
                          _buildDivider(isDark),
                          _buildSwitchTile(
                            icon:
                                _isPrivate
                                    ? Icons.lock_outline_rounded
                                    : Icons.lock_open_rounded,
                            iconColor: const Color(0xFFFF9A44),
                            title: "Private Account",
                            subtitle: "Only your mingles can see your posts",
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            value: _isPrivate,
                            onChanged: _togglePrivacy,
                          ),
                          _buildDivider(isDark),
                          _buildListTile(
                            icon: Icons.notifications_none_rounded,
                            iconColor: const Color(0xFFFF3E8E),
                            title: "Notifications",
                            subtitle: "Manage push alerts and sounds",
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            const NotificationSettingsScreen(),
                                  ),
                                ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // --- SUPPORT SECTION ---
                  _buildSectionTitle("Support & About", textColor),
                  _buildSettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    children: [
                      _buildListTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: Colors.blueGrey,
                        title: "Help Center",
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterScreen(),
                              ),
                            ),
                      ),
                      _buildDivider(isDark),
                      _buildListTile(
                        icon: Icons.description_outlined,
                        iconColor: Colors.blueGrey,
                        title: "Terms of Service & Privacy",
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsAndPrivacyScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- LOGIN/ACTIONS SECTION ---
                  _buildSectionTitle("Login", textColor),
                  _buildSettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    children: [
                      _buildActionTile(
                        icon: Icons.logout_rounded,
                        title: "Log Out",
                        color: Colors.orange,
                        onTap: _logout,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        icon: Icons.delete_forever_rounded,
                        title: "Delete Account",
                        color: Colors.red,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // App Version
                  Center(
                    child: Text(
                      "Ente RIT v1.0.0",
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
    );
  }

  // Helper Widgets
  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor.withOpacity(0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required List<Widget> children,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor),
              )
              : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: subtitleColor),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF673AB7),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}

// ============================================================================
// SUB-SCREENS FOR SETTINGS (Built natively into the app for a pro feel)
// ============================================================================

/// 1. PERSONAL INFORMATION SCREEN
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final User user = FirebaseAuth.instance.currentUser!;

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
          "Personal Info",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF43E97B)),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final studentId = data['studentId'] ?? 'N/A';
          final role = data['role'] ?? 'Student';

          // Format Account Creation Date
          final creationTime = user.metadata.creationTime;
          final joinedDate =
              creationTime != null
                  ? DateFormat('MMMM d, yyyy').format(creationTime)
                  : 'Unknown';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "This information is private and is only used to secure your account and verify your identity within the campus network.",
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
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
                    _buildInfoTile(
                      "Email Address",
                      user.email ?? "No Email",
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Student / Staff ID",
                      studentId,
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Account Role",
                      role.toString().toUpperCase(),
                      textColor,
                      isDark,
                    ),
                    _buildDivider(isDark),
                    _buildInfoTile(
                      "Member Since",
                      joinedDate,
                      textColor,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    Color textColor,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}

/// 2. NOTIFICATION SETTINGS SCREEN
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

/// 3. HELP CENTER SCREEN
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@enterit.com',
      query: 'subject=Ente RIT App Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No email client configured on this device."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final List<Map<String, String>> faqs = [
      {
        "question": "How do I change my profile picture?",
        "answer":
            "Go to Settings > Edit Profile, and tap on your current avatar to upload a new picture from your gallery or camera.",
      },
      {
        "question": "How do I report inappropriate content?",
        "answer":
            "Tap the three-dot menu (...) on the top right of any post and select 'Report'. Our admin team will review it shortly.",
      },
      {
        "question": "How do I make my account private?",
        "answer":
            "Navigate to Settings > Preferences > Private Account. When toggled on, only your connected mingles can view your posts.",
      },
      {
        "question": "I found a bug. What do I do?",
        "answer":
            "Please use the 'Contact Support' button below to send us an email with a description of the issue.",
      },
    ];

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
          "Help Center",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Frequently Asked Questions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
              itemBuilder: (context, index) {
                return ExpansionTile(
                  iconColor: Colors.blueGrey,
                  collapsedIconColor: Colors.grey,
                  title: Text(
                    faqs[index]['question']!,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faqs[index]['answer']!,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined, color: Colors.white),
            label: Text(
              "Contact Support",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _contactSupport(context),
          ),
        ],
      ),
    );
  }
}

/// 4. TERMS AND PRIVACY SCREEN
class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

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
          "Terms & Privacy",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Terms of Service & Privacy Policy",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Last updated: October 2023",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildTextSection(
                "1. Introduction",
                "Welcome to Ente RIT. By using our application, you agree to these terms. Please read them carefully. The app is designed exclusively for the students, faculty, and staff of Rajiv Gandhi Institute of Technology (RIT), Kottayam.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "2. User Data & Privacy",
                "We respect your privacy. Your email, student ID, and profile information are stored securely on our servers to verify your identity within the campus network. We do not sell your personal data to third parties. You have the right to delete your account and all associated data at any time via the Settings menu.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "3. Community Guidelines",
                "Ente RIT relies on a safe, respectful environment. Harassment, bullying, hate speech, and the posting of explicit or inappropriate content are strictly prohibited. Violations will result in immediate account termination. Use the 'Report' feature to notify admins of any concerning behavior.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "4. Intellectual Property",
                "You retain ownership of the content you post. However, by posting, you grant Ente RIT a license to display that content within the application. Do not post copyrighted material without permission.",
                textColor,
                isDark,
              ),
              _buildTextSection(
                "5. Limitation of Liability",
                "Ente RIT is provided 'as is'. We do not guarantee that the app will be error-free or uninterrupted. We are not responsible for user-generated content or interactions between users.",
                textColor,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection(
    String title,
    String content,
    Color textColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
