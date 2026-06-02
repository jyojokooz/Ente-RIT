// ===============================
// FILE NAME: share_profile_sheet.dart
// FILE PATH: lib/widgets/profile/share_profile_sheet.dart
// ===============================

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ShareProfileSheet extends StatefulWidget {
  final String userId;
  final String username;
  final String displayName;
  final String? profilePhotoUrl;

  const ShareProfileSheet({
    super.key,
    required this.userId,
    required this.username,
    required this.displayName,
    this.profilePhotoUrl,
  });

  @override
  State<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends State<ShareProfileSheet> {
  bool _showQr = false;
  bool _isSharing = false;

  // Key used to capture the QR Code as an image
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _showQr = true;
        });
      }
    });
  }

  // --- THE FIX: Capture QR Code and Share as Image + Text ---
  Future<void> _shareProfileWithQr(String profileLink) async {
    if (!_showQr) return; // Wait for QR to load

    setState(() => _isSharing = true);

    try {
      // 1. Capture the QR Code widget as an image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High quality
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/profile_qr.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Share the Image AND the Link
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Let's mingle on Ente RIT! Check out my profile: $profileLink",
        subject: "Connect with ${widget.displayName} on Ente RIT",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sharing profile: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // TO THIS:
    final String profileLink =
        "https://fir-auth-bfed9.web.app/profile/${widget.userId}";

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Share Profile",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // --- WRAP CARD IN REPAINT BOUNDARY TO CAPTURE IT ---
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: bgColor,
                      backgroundImage:
                          (widget.profilePhotoUrl != null &&
                                  widget.profilePhotoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                widget.profilePhotoUrl!,
                              )
                              : null,
                      child:
                          (widget.profilePhotoUrl == null ||
                                  widget.profilePhotoUrl!.isEmpty)
                              ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 35,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "@${widget.username}",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF3E8E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    height: 184,
                    width: 184,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          _showQr
                              ? QrImageView(
                                data: profileLink,
                                version: QrVersions.auto,
                                size: 160.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.circle,
                                  color: Color(0xFFFF3E8E),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: Colors.black87,
                                ),
                                embeddedImage: const AssetImage(
                                  'assets/app_icon.png',
                                ),
                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                  size: Size(30, 30),
                                ),
                              )
                              : const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF3E8E),
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: profileLink));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Link copied to clipboard!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: Text(
                    "Copy Link",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF161618) : Colors.grey.shade200,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSharing || !_showQr
                            ? null
                            : () => _shareProfileWithQr(profileLink),
                    icon:
                        _isSharing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.ios_share_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    label: Text(
                      _isSharing ? "Sharing..." : "Share",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
