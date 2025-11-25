// ===============================
// FILE NAME: post_card.dart
// FILE PATH: lib/screens/post_card.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'full_screen_image_viewer.dart';
import 'full_screen_video_player.dart';

class PostCard extends StatelessWidget {
  final DocumentSnapshot postSnapshot;
  final Function() onCommentPressed;
  final Function() onDeletePressed;
  final Function() onProfileTapped;
  final Function() onLikePressed;
  final Function() onEditPressed;

  const PostCard({
    super.key,
    required this.postSnapshot,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onProfileTapped,
    required this.onLikePressed,
    required this.onEditPressed,
  });

  // --- FIX 1: BETTER QUALITY URL ---
  // Increased width to 1280 and set quality to best to fix blurriness
  String getOptimizedCloudinaryUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) {
      return originalUrl;
    }
    const transformations = 'w_1280,q_auto:best,f_auto'; // Higher Res
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final postData = postSnapshot.data() as Map<String, dynamic>?;
    if (postData == null) return const SizedBox.shrink();

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    const Color brandBlack = Colors.black;
    const Color brandWhite = Colors.white;
    const Color brandPurple = Color(0xFF9983F3);

    final authorData = {
      'displayName': postData['userName'] ?? 'Unknown User',
      'username': postData['username'] ?? '',
      'profilePhotoUrl': postData['userImageUrl'] ?? '',
    };

    final String originalMediaUrl = postData['postMediaUrl'] ?? postData['postImageUrl'] ?? '';
    final String? originalThumbnailUrl = postData['postThumbnailUrl'];
    final String postType = postData['postType'] ?? 'image';
    final String caption = postData['caption'] ?? '';
    final bool isAuthor = postData['userId'] == currentUserId;
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final String heroTag = 'postImage-${postSnapshot.id}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: brandWhite,
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: brandBlack, width: 3), 
        boxShadow: const [
          BoxShadow(
            color: brandBlack,
            offset: Offset(6, 6), 
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. HEADER ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onProfileTapped,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brandBlack, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: authorData['profilePhotoUrl'].isNotEmpty 
                          ? NetworkImage(authorData['profilePhotoUrl']) 
                          : null,
                      child: authorData['profilePhotoUrl'].isEmpty 
                          ? const Icon(Icons.person, color: brandBlack) 
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorData['displayName'],
                        style: GoogleFonts.archivoBlack(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: brandBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (authorData['username'].isNotEmpty)
                        Text(
                          '@${authorData['username']}',
                          style: GoogleFonts.spaceMono(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: brandBlack),
                    onPressed: () => onEditPressed(),
                  ),
              ],
            ),
          ),

          // --- 2. MEDIA CONTENT (NO CROPPING FIX) ---
          if (originalMediaUrl.isNotEmpty)
            Container(
              width: double.infinity,
              // Border only on top and bottom of image
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: brandBlack, width: 3)),
                color: Colors.black, // Background for letterboxing if needed
              ),
              // Use ConstrainedBox instead of fixed height
              // This allows image to be its natural height, up to 550px
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 200, 
                  maxHeight: 550, // Taller max height to prevent cropping vertical photos
                ),
                child: (postType == 'video')
                    ? _buildVideoPlayer(context, originalMediaUrl, originalThumbnailUrl)
                    : _buildImageViewer(context, originalMediaUrl, heroTag),
              ),
            ),

          // --- 3. ACTIONS & CAPTION ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(postSnapshot.id).snapshots(),
                  builder: (context, postStreamSnapshot) {
                    final likesData = postStreamSnapshot.hasData ? postStreamSnapshot.data!.data() as Map<String, dynamic> : postData;
                    final rtLikes = likesData['likes'] ?? [];
                    final bool isLiked = rtLikes.contains(currentUserId);

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('posts').doc(postSnapshot.id).collection('comments').snapshots(),
                      builder: (context, commentStreamSnapshot) {
                        final commentCount = commentStreamSnapshot.hasData ? commentStreamSnapshot.data!.docs.length : (postData['comments'] ?? 0);

                        return Row(
                          children: [
                            // LIKE BUTTON
                            GestureDetector(
                              onTap: onLikePressed,
                              child: Container(
                                width: 80, 
                                height: 45,
                                decoration: BoxDecoration(
                                  color: isLiked ? brandPurple : Colors.white, 
                                  border: Border.all(color: brandBlack, width: 2.5),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [BoxShadow(color: brandBlack, offset: Offset(3, 3), blurRadius: 0)],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite, 
                                      color: isLiked ? Colors.white : brandBlack, 
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${rtLikes.length}",
                                      style: GoogleFonts.archivoBlack(
                                        fontWeight: FontWeight.bold,
                                        color: isLiked ? Colors.white : brandBlack,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 16), 

                            // COMMENT BUTTON
                            GestureDetector(
                              onTap: onCommentPressed,
                              child: Container(
                                width: 80,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.black, 
                                  border: Border.all(color: brandBlack, width: 2.5),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [BoxShadow(color: Colors.grey, offset: Offset(3, 3), blurRadius: 0)],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$commentCount",
                                      style: GoogleFonts.archivoBlack(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            
                            Text(
                              timestamp != null ? DateFormat('MMM d').format(timestamp) : '',
                              style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    caption,
                    style: GoogleFonts.spaceMono(
                      color: brandBlack,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context, String originalImageUrl, String heroTag) {
    final String optimizedUrl = getOptimizedCloudinaryUrl(originalImageUrl);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageViewer(imageUrl: originalImageUrl, heroTag: heroTag)));
      },
      child: Hero(
        tag: heroTag,
        child: Image.network(
          optimizedUrl,
          // FIX 2: Changed from cover to fitWidth to prevent cropping
          // It will span the width, and the container height will adjust naturally
          fit: BoxFit.cover, 
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 300, // Placeholder height while loading
              color: Colors.grey.shade100,
              child: const Center(child: Icon(Icons.image, color: Colors.grey)),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 300, 
            color: Colors.grey.shade200, 
            child: const Icon(Icons.broken_image)
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, String originalVideoUrl, String? originalThumbnailUrl) {
    final String optimizedThumbnailUrl = originalThumbnailUrl != null ? getOptimizedCloudinaryUrl(originalThumbnailUrl) : 'https://via.placeholder.com/600x600/000000/FFFFFF/?text=Video';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenVideoPlayer(videoUrl: originalVideoUrl)));
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Thumbnail
          Image.network(
            optimizedThumbnailUrl,
            fit: BoxFit.cover, // Thumbnails are usually ok to cover
            width: double.infinity,
            // FIX 3: Let height adjust, but keep reasonable constraints via parent
            errorBuilder: (context, error, stackTrace) => Container(height: 300, color: Colors.grey.shade200),
          ),
          
          // Play Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Icon(Icons.play_arrow, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }
}