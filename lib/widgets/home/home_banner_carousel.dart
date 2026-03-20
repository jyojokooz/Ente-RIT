import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBannerCarousel extends StatefulWidget {
  final bool isDark;
  const HomeBannerCarousel({super.key, required this.isDark});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  // Start at a large offset to allow infinite sliding
  late final PageController _pageController;
  final int _initialPageOffset = 1000;
  Timer? _timer;
  int _currentPage = 0;
  int _totalBanners = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPageOffset);
    _currentPage = _initialPageOffset;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int total) {
    _totalBanners = total;
    _timer?.cancel();
    if (total > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
        if (_pageController.hasClients) {
          // Slide in one direction (right to left)
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  Future<void> _launchURL(String? urlStr) async {
    if (urlStr == null || urlStr.trim().isEmpty) return;
    final uri = Uri.parse(urlStr.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('home_banners')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final banners = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_totalBanners != banners.length) {
            _startAutoSlide(banners.length);
          }
        });

        return Column(
          children: [
            Container(
              height: 90, // Restored height to match 728x90 banner proportion
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!widget.isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Infinite Loop PageView
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    // Loop the index over the total banners array length
                    final realIndex = index % banners.length;
                    final data =
                        banners[realIndex].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap:
                          () => _launchURL(
                            data['linkUrl'],
                          ), // Clicks redirect to URL
                      child: CachedNetworkImage(
                        imageUrl: data['imageUrl'] ?? '',
                        fit:
                            BoxFit
                                .cover, // Expands image fully across container
                        placeholder:
                            (context, url) => Container(
                              color:
                                  widget.isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color:
                                  widget.isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Dots Indicator
            if (banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  final realCurrentPage = _currentPage % banners.length;
                  bool isSelected = (realCurrentPage == index);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: isSelected ? 18 : 6,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF00C569)
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
          ],
        );
      },
    );
  }
}
