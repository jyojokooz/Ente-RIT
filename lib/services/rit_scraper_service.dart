// ===============================
// FILE NAME: rit_scraper_service.dart
// FILE PATH: lib/services/rit_scraper_service.dart
// ===============================

import 'dart:convert';
import 'dart:developer'; // For logging
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class HODModel {
  final String name;
  final String designation;
  final String message;
  final String imageUrl;

  HODModel({
    required this.name,
    required this.designation,
    required this.message,
    required this.imageUrl,
  });
}

class FacultyModel {
  final int id;
  final String name;
  final String designation;
  final String imageUrl;
  final String email;
  final String type; // 'Teaching' or 'Non-Teaching'

  FacultyModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.imageUrl,
    this.email = '',
    required this.type,
  });
}

class StaffProfileModel {
  final String name;
  final String designation;
  final String department;
  final String address;
  final String email;
  final String phone;
  final String joinDate;
  final String photoUrl;
  final List<Map<String, String>> education;
  final List<Map<String, String>> experience;

  StaffProfileModel({
    required this.name,
    required this.designation,
    required this.department,
    required this.address,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.photoUrl,
    required this.education,
    required this.experience,
  });
}

class RitScraperService {
  final String baseUrl = "https://www.rit.ac.in";
  final String etlabBaseUrl = "https://rit.etlab.in/uploads/images/staff/";
  final String defaultUserImage =
      "https://rit.etlab.in/images/default-user.png";

  // --- SCRAPE HOD DETAILS ---
  Future<HODModel> getHODDetails(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Mozilla/5.0"},
      );
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        String imageUrl = "";
        var imgElement = document.querySelector('.team-img img');
        if (imgElement != null) {
          var src = imgElement.attributes['src'];
          if (src != null)
            imageUrl = src.startsWith('http') ? src : "$baseUrl/$src";
        }
        String name =
            document.querySelector('.team-bio h5 a')?.text.trim() ??
            "Head of Department";
        String designation =
            document.querySelector('.team-bio span')?.text.trim() ?? "HOD";
        String message =
            document
                .querySelector('.about-text')
                ?.text
                .trim()
                .replaceAll(RegExp(r'\s+'), ' ') ??
            "";

        return HODModel(
          name: name,
          designation: designation,
          message: message,
          imageUrl: imageUrl,
        );
      }
      throw Exception("Failed to load");
    } catch (e) {
      return HODModel(
        name: "Error",
        designation: "Error",
        message: "Error",
        imageUrl: "",
      );
    }
  }

  // --- SCRAPE PLACEMENT IMAGES ---
  Future<List<String>> getPlacementImages(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Mozilla/5.0"},
      );
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        List<String> imageUrls = [];
        var carouselItems = document.querySelectorAll(
          '#owl-carousel .item img',
        );
        for (var img in carouselItems) {
          var src = img.attributes['src'];
          if (src != null && src.isNotEmpty)
            imageUrls.add(src.startsWith('http') ? src : "$baseUrl/$src");
        }
        return imageUrls;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- FETCH FACULTY FROM API ---
  Future<List<FacultyModel>> fetchFacultyFromApi(int departmentId) async {
    final String apiUrl =
        "https://rit.etlab.in/website/webapi/department/$departmentId";

    log("Fetching faculty from: $apiUrl"); // Debug Log

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<FacultyModel> facultyList = [];

        void processStaffList(List<dynamic>? staffList, String type) {
          if (staffList == null) return;
          for (var staff in staffList) {
            String photo = staff['photo']?.toString() ?? "";
            String imageUrl =
                (photo == "undefined" || photo.isEmpty || photo == "null")
                    ? defaultUserImage
                    : "$etlabBaseUrl$photo";

            // Safely parse ID
            int id = 0;
            if (staff['id'] is int) {
              id = staff['id'];
            } else if (staff['id'] is String) {
              id = int.tryParse(staff['id']) ?? 0;
            }

            facultyList.add(
              FacultyModel(
                id: id,
                name: staff['name']?.toString() ?? "Unknown",
                designation: staff['designation']?.toString() ?? "",
                imageUrl: imageUrl,
                email: staff['email']?.toString() ?? "",
                type: type,
              ),
            );
          }
        }

        // Process all categories provided by the API
        processStaffList(data['regular_teaching_staff'], 'Faculty');
        processStaffList(data['adhoc_teaching_staff'], 'Faculty');
        processStaffList(data['non_teaching_staff'], 'Technical Staff');

        log("Fetched ${facultyList.length} staff members."); // Debug Log
        return facultyList;
      } else {
        log("API Error: ${response.statusCode}");
        throw Exception('Failed to load faculty: ${response.statusCode}');
      }
    } catch (e) {
      log("Scraper Error: $e");
      throw Exception("Error fetching data: $e");
    }
  }

  // --- FETCH STAFF PROFILE ---
  Future<StaffProfileModel?> fetchStaffProfile(int staffId) async {
    final String apiUrl = "https://rit.etlab.in/profile/staff/";

    try {
      final response = await http.get(Uri.parse("$apiUrl?id=$staffId"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['basic_details'] == null ||
            (data['basic_details'] as List).isEmpty) {
          return null;
        }

        final basic = (data['basic_details'] as List).first;
        String photo = basic['photo']?.toString() ?? "";
        String imageUrl =
            (photo == "undefined" || photo.isEmpty || photo == "null")
                ? defaultUserImage
                : "$etlabBaseUrl$photo";

        List<Map<String, String>> education = [];
        if (data['education'] != null) {
          for (var edu in data['education']) {
            education.add({
              'degree': edu['degree']?.toString() ?? '',
              'university': edu['university']?.toString() ?? '',
              'year': edu['year']?.toString() ?? '',
            });
          }
        }

        List<Map<String, String>> experience = [];
        if (data['professional_experience'] != null) {
          for (var exp in data['professional_experience']) {
            experience.add({
              'institution': exp['institution']?.toString() ?? '',
              'designation': exp['designation']?.toString() ?? '',
              'period': "${exp['from_date'] ?? ''} - ${exp['to_date'] ?? ''}",
            });
          }
        }

        return StaffProfileModel(
          name: basic['name']?.toString() ?? '',
          designation: basic['designation']?.toString() ?? '',
          department: basic['department']?.toString() ?? '',
          address: basic['address']?.toString() ?? '',
          email: basic['email']?.toString() ?? '',
          phone: basic['phone']?.toString() ?? '',
          joinDate: basic['joindate']?.toString() ?? '',
          photoUrl: imageUrl,
          education: education,
          experience: experience,
        );
      }
      return null;
    } catch (e) {
      log("Profile Error: $e");
      return null;
    }
  }
}
