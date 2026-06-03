// ===============================
// FILE NAME: rit_scraper_service.dart
// FILE PATH: lib/features/campus/data/rit_scraper_service.dart
// ===============================

// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW IMPORT ADDED

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
  final String type;

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

  // Get Cloudflare Worker URL from .env
  String get _workerUrl => dotenv.env['CLOUDFLARE_WORKER_URL'] ?? '';

  // --- SECURE PROXY FETCH ---
  // Sends the URL to Cloudflare Worker. The worker bypasses SSL issues and returns the text.
  Future<String> _secureFetch(String targetUrl) async {
    if (_workerUrl.isEmpty) {
      throw Exception("CLOUDFLARE_WORKER_URL is not set in .env");
    }

    // --- SECURITY FIX: Attach Firebase Auth Token ---
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : '';

    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer $token', // Secures the endpoint from public abuse
      },
      body: jsonEncode({'type': 'proxy', 'url': targetUrl}),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("Proxy fetch failed: ${response.statusCode}");
    }
  }

  // --- SCRAPE HOD DETAILS ---
  Future<HODModel> getHODDetails(String url) async {
    try {
      final htmlBody = await _secureFetch(url);
      var document = parser.parse(htmlBody);

      String imageUrl = "";
      var imgElement = document.querySelector('.team-img img');
      if (imgElement != null) {
        var src = imgElement.attributes['src'];
        if (src != null) {
          imageUrl = src.startsWith('http') ? src : "$baseUrl/$src";
        }
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
    } catch (e) {
      log("HOD Fetch Error: $e");
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
      final htmlBody = await _secureFetch(url);
      var document = parser.parse(htmlBody);

      List<String> imageUrls = [];
      var carouselItems = document.querySelectorAll('#owl-carousel .item img');
      for (var img in carouselItems) {
        var src = img.attributes['src'];
        if (src != null && src.isNotEmpty) {
          imageUrls.add(src.startsWith('http') ? src : "$baseUrl/$src");
        }
      }
      return imageUrls;
    } catch (e) {
      log("Placement Images Fetch Error: $e");
      return [];
    }
  }

  // --- FETCH FACULTY FROM API ---
  Future<List<FacultyModel>> fetchFacultyFromApi(int departmentId) async {
    final String apiUrl =
        "https://rit.etlab.in/website/webapi/department/$departmentId";

    try {
      final jsonBody = await _secureFetch(apiUrl);
      final Map<String, dynamic> data = json.decode(jsonBody);

      List<FacultyModel> facultyList = [];

      void processStaffList(List<dynamic>? staffList, String type) {
        if (staffList == null) return;
        for (var staff in staffList) {
          String photo = staff['photo']?.toString() ?? "";
          String imageUrl =
              (photo == "undefined" || photo.isEmpty || photo == "null")
                  ? defaultUserImage
                  : "$etlabBaseUrl$photo";

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

      processStaffList(data['regular_teaching_staff'], 'Faculty');
      processStaffList(data['adhoc_teaching_staff'], 'Faculty');
      processStaffList(data['non_teaching_staff'], 'Technical Staff');

      return facultyList;
    } catch (e) {
      log("Faculty API Error: $e");
      throw Exception("Error fetching faculty data: $e");
    }
  }

  // --- FETCH STAFF PROFILE ---
  Future<StaffProfileModel?> fetchStaffProfile(int staffId) async {
    final String apiUrl = "https://rit.etlab.in/profile/staff/?id=$staffId";

    try {
      final jsonBody = await _secureFetch(apiUrl);
      final Map<String, dynamic> data = json.decode(jsonBody);

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
    } catch (e) {
      log("Staff Profile Error: $e");
      return null;
    }
  }
}
