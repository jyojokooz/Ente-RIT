// ===============================
// FILE NAME: edit_profile_form.dart
// FILE PATH: lib/widgets/edit_profile/edit_profile_form.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final TextEditingController statusController;
  final TextEditingController linkedinController;
  final TextEditingController githubController;
  final TextEditingController portfolioController;

  final List<String> departmentOptions;
  final String? selectedDepartment;
  final ValueChanged<String?> onDepartmentChanged;

  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const EditProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.usernameController,
    required this.bioController,
    required this.statusController,
    required this.linkedinController,
    required this.githubController,
    required this.portfolioController,
    required this.departmentOptions,
    required this.selectedDepartment,
    required this.onDepartmentChanged,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Basic Details"),
            const SizedBox(height: 16),
            _buildTextField(
              controller: nameController,
              label: "Full Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: usernameController,
              label: "Username",
              icon: Icons.alternate_email,
              isUsername: true,
            ),
            const SizedBox(height: 16),
            _buildDepartmentDropdown(),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),

            _buildSectionLabel("About Me"),
            const SizedBox(height: 16),
            _buildTextField(
              controller: bioController,
              label: "Bio",
              icon: Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: statusController,
              label: "Current Status",
              icon: Icons.emoji_emotions_outlined,
              hint: "e.g., Coding in the lab 💻",
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1),
            ),

            _buildSectionLabel("Social Links (Optional)"),
            const SizedBox(height: 16),
            _buildTextField(
              controller: linkedinController,
              label: "LinkedIn Profile URL",
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: githubController,
              label: "GitHub Profile URL",
              icon: Icons.code,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: portfolioController,
              label: "Portfolio / Website URL",
              icon: Icons.public,
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isUsername = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: subtitleColor, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: subtitleColor.withOpacity(0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: subtitleColor, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF161618) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (label == 'Full Name' && (value == null || value.trim().isEmpty)) {
          return 'Name is required';
        }
        if (isUsername) {
          if (value == null || value.trim().isEmpty)
            return 'Username is required';
          if (value.contains(' ') || value.contains('@')) {
            return 'No spaces or @ allowed';
          }
          if (value.length < 3) return 'Min 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDepartment,
      isExpanded: true, // <-- FIX 1: Allow dropdown to expand horizontally
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
      dropdownColor: isDark ? const Color(0xFF252528) : Colors.white,
      style: GoogleFonts.poppins(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: "Department",
        labelStyle: GoogleFonts.poppins(color: subtitleColor, fontSize: 13),
        prefixIcon: Icon(Icons.school_outlined, color: subtitleColor, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF161618) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items:
          departmentOptions.map((String dept) {
            return DropdownMenuItem(
              value: dept,
              child: Text(
                dept,
                maxLines: 1, // <-- FIX 2: Restrict to 1 line
                overflow:
                    TextOverflow
                        .ellipsis, // <-- FIX 3: Add ellipsis "..." if it overflows
              ),
            );
          }).toList(),
      onChanged: onDepartmentChanged,
      validator: (val) => val == null ? 'Department is required' : null,
    );
  }
}
