import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable and stylish card widget for displaying a single Lost & Found item.
/// It includes owner-specific actions like Edit and Delete.
class LostFoundItemCard extends StatelessWidget {
  final String title;
  final String status;
  final String location;
  final String userName;
  final String? imageUrl;
  final bool isResolved;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LostFoundItemCard({
    super.key,
    required this.title,
    required this.status,
    required this.location,
    required this.userName,
    this.imageUrl,
    this.isResolved = false,
    this.isOwner = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.grey.shade900,
        child: Stack(
          children: [
            _buildBackgroundImage(),
            _buildGradientOverlay(),
            _buildTextContent(context),
            if (isResolved) _buildResolvedBanner(),
            if (isOwner && !isResolved) _buildOwnerOptionsButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds the background image with loading and error placeholders.
  Widget _buildBackgroundImage() {
    return (imageUrl != null && imageUrl!.isNotEmpty)
        ? Positioned.fill(
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder:
                (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
            errorBuilder:
                (context, error, stack) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
          ),
        )
        : Container(color: Colors.grey.shade800);
  }

  /// Builds a gradient over the image to ensure text is always readable.
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withAlpha(204),
              Colors.transparent,
              Colors.black.withAlpha(204),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  /// Builds the main text content, including title, location, and user name.
  Widget _buildTextContent(BuildContext context) {
    final statusColor =
        status == 'lost' ? Colors.orange.shade300 : Colors.lightBlue.shade300;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "by $userName",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the three-dot options menu for the item's owner.
  Widget _buildOwnerOptionsButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        // Corrected from withOpacity to withAlpha
        color: Colors.black.withAlpha(128), // 128 is 50% opacity
        borderRadius: BorderRadius.circular(20),
        child: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
        ),
      ),
    );
  }

  /// Builds the diagonal "RESOLVED" banner.
  Widget _buildResolvedBanner() {
    return Positioned(
      top: 10,
      right: -45,
      child: Transform.rotate(
        angle: 0.785398, // 45 degrees in radians
        child: Container(
          color: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 2),
          child: Text(
            "RESOLVED",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
