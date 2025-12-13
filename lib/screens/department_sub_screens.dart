// ===============================
// FILE NAME: department_sub_screens.dart
// FILE PATH: lib/screens/department_sub_screens.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/rit_scraper_service.dart';
import 'full_screen_image_viewer.dart'; // Make sure to import your existing full screen viewer

// --- HOD INFO SCREEN ---
class HodInfoScreen extends StatelessWidget {
  final String url;
  const HodInfoScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final RitScraperService scraper = RitScraperService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "HOD's Desk",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<HODModel>(
        future: scraper.getHODDetails(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          if (snapshot.hasError)
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.black),
              ),
            );
          final hod = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (hod.imageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullScreenImageViewer(
                                imageUrl: hod.imageUrl,
                                heroTag: 'hod_img',
                              ),
                        ),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'hod_img',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            hod.imageUrl.isNotEmpty
                                ? NetworkImage(hod.imageUrl)
                                : null,
                        child:
                            hod.imageUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  hod.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  hod.designation,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Message from HOD",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        hod.message.isNotEmpty
                            ? hod.message
                            : "No message available.",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- FACULTY LIST SCREEN ---
class FacultyListScreen extends StatelessWidget {
  final String url;
  const FacultyListScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final RitScraperService scraper = RitScraperService();
    const int mcaDepartmentId = 8;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Staff Members",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<FacultyModel>>(
        future: scraper.fetchFacultyFromApi(mcaDepartmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No staff found.",
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          }

          final allStaff = snapshot.data!;
          final faculty = allStaff.where((s) => s.type == 'Faculty').toList();
          final techStaff =
              allStaff.where((s) => s.type == 'Technical Staff').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (faculty.isNotEmpty) ...[
                  _SectionHeader(title: "Faculty"),
                  _StaffGrid(staffList: faculty),
                  const SizedBox(height: 30),
                ],
                if (techStaff.isNotEmpty) ...[
                  _SectionHeader(title: "Technical Staff"),
                  _StaffGrid(staffList: techStaff),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Colors.blueAccent, width: 4),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _StaffGrid extends StatelessWidget {
  final List<FacultyModel> staffList;
  const _StaffGrid({required this.staffList});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffProfileScreen(staffId: staff.id),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'staff_list_${staff.id}',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: NetworkImage(staff.imageUrl),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    staff.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    staff.designation,
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- STAFF PROFILE SCREEN ---
class StaffProfileScreen extends StatelessWidget {
  final int staffId;
  const StaffProfileScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    final RitScraperService scraper = RitScraperService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<StaffProfileModel?>(
        future: scraper.fetchStaffProfile(staffId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          if (snapshot.hasError)
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.black),
              ),
            );
          if (!snapshot.hasData || snapshot.data == null)
            return const Center(
              child: Text(
                "Profile details unavailable.",
                style: TextStyle(color: Colors.black),
              ),
            );

          final profile = snapshot.data!;

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder:
                  (context, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FullScreenImageViewer(
                                          imageUrl: profile.photoUrl,
                                          heroTag: 'staff_full_$staffId',
                                        ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'staff_full_$staffId',
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(
                                    profile.photoUrl,
                                  ),
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              profile.designation,
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (profile.email.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      profile.email,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[800],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        const TabBar(
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blueAccent,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(text: "Education"),
                            Tab(text: "Experience"),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ],
              body: TabBarView(
                children: [
                  // Education Tab
                  profile.education.isEmpty
                      ? const Center(
                        child: Text(
                          "No education info added.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: profile.education.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final edu = profile.education[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.school,
                                color: Colors.orangeAccent,
                              ),
                              title: Text(
                                edu['degree']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                "${edu['university']}\n${edu['year']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                  // Experience Tab
                  profile.experience.isEmpty
                      ? const Center(
                        child: Text(
                          "No experience info added.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: profile.experience.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exp = profile.experience[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.work,
                                color: Colors.blueAccent,
                              ),
                              title: Text(
                                exp['designation']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                "${exp['institution']}\n${exp['period']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// --- PLACEMENT INFO SCREEN ---
class PlacementInfoScreen extends StatelessWidget {
  final String url;
  const PlacementInfoScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final RitScraperService scraper = RitScraperService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Placement Highlights",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<String>>(
        future: scraper.getPlacementImages(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(
              child: Text(
                "No placement images found.",
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            );
          final images = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: images.length,
            separatorBuilder: (c, i) => const SizedBox(height: 20),
            itemBuilder:
                (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    placeholder:
                        (c, u) =>
                            Container(height: 200, color: Colors.grey[200]),
                    fit: BoxFit.cover,
                  ),
                ),
          );
        },
      ),
    );
  }
}
