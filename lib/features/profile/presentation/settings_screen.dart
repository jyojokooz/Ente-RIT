// lib/features/profile/presentation/settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_project/core/constants/theme_provider.dart';
import 'package:my_project/features/profile/presentation/edit_profile_screen.dart';

// --- IMPORT THE NEW CONNECTOR ---
import 'package:my_project/features/profile/presentation/settings/settings_connector.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({'isPrivate': isPrivate});

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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
        );

        final userId = _currentUser.uid;
        final firestore = FirebaseFirestore.instance;

        // --- GLOBAL DATABASE CLEANUP (Ghost Data Fix) ---
        final connectionsQuery =
            await firestore
                .collection('users')
                .where('connections', arrayContains: userId)
                .get();
        for (var doc in connectionsQuery.docs) {
          doc.reference.update({
            'connections': FieldValue.arrayRemove([userId]),
          });
        }

        final sentQuery =
            await firestore
                .collection('users')
                .where('sentRequests', arrayContains: userId)
                .get();
        for (var doc in sentQuery.docs) {
          doc.reference.update({
            'sentRequests': FieldValue.arrayRemove([userId]),
          });
        }

        final receivedQuery =
            await firestore
                .collection('users')
                .where('receivedRequests', arrayContains: userId)
                .get();
        for (var doc in receivedQuery.docs) {
          doc.reference.update({
            'receivedRequests': FieldValue.arrayRemove([userId]),
          });
        }

        // Delete Firestore Document First
        await firestore.collection('users').doc(userId).delete();

        // Delete Authentication Record
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
    final currentThemeMode = ref.watch(themeProvider);
    final isAppDarkMode = currentThemeMode == ThemeMode.dark;

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
                  _buildSectionTitle("Preferences", textColor),
                  _buildSettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    children: [
                      _buildSwitchTile(
                        icon:
                            isAppDarkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                        iconColor: const Color(0xFF673AB7),
                        title: "Dark Mode",
                        subtitle: "Switch between light and dark themes",
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        value: isAppDarkMode,
                        onChanged:
                            (val) => ref
                                .read(themeProvider.notifier)
                                .toggleTheme(val),
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
                                    (_) => const NotificationSettingsScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
