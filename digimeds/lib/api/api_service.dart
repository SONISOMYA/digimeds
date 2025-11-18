import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digimeds/models/prescription_model.dart';

class ApiService {
  // Use 127.0.0.1 for iOS Simulator.
  // If using Android Emulator, use 'http://10.0.2.2:8000'
  static const String baseUrl = "http://127.0.0.1:8000";

  // 1. Upload Image to Gemini
  static Future<Prescription> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/scan'));
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return prescriptionFromJson(responseBody);
      } else {
        throw Exception(
          'Failed to upload image. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred during upload: $e');
    }
  }

  // 2. Save Prescription to Firestore
  static Future<void> savePrescription(Prescription prescription) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Get the secure token to send to backend
    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/save-prescription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(prescription.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save prescription: ${response.body}');
    }
  }

  // 3. Get Prescriptions for Dashboard
  static Future<List<Prescription>> getPrescriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Prescription.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  // 4. Delete Prescription (Added this!)
  static Future<void> deletePrescription(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    final token = await user.getIdToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/delete-prescription/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete: ${response.body}');
    }
  }
}
