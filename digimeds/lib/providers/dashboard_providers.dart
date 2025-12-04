// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:digimeds/models/prescription_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// // --- Mock Data (Placeholder) ---
// // In a real app, this data would come from your Firebase database.
// final mockRecentPrescriptions = [
//   Prescription(
//     doctorName: "Dr. Sharma",
//     prescriptionDate: "2025-10-10",
//     medications: [Medication(drugName: "Paracetamol")],
//   ),
//   Prescription(
//     doctorName: "Dr. Gupta",
//     prescriptionDate: "2025-10-08",
//     medications: [
//       Medication(drugName: "Amoxicillin"),
//       Medication(drugName: "Ibuprofen"),
//     ],
//   ),
// ];

// // --- Riverpod Providers ---

// // A provider to get the user's name
// final userNameProvider = Provider<String>((ref) {
//   final user = FirebaseAuth.instance.currentUser;
//   return user?.displayName ?? user?.email?.split('@').first ?? "User";
// });

// // A FutureProvider to simulate fetching recent prescriptions
// final recentPrescriptionsProvider = FutureProvider<List<Prescription>>((
//   ref,
// ) async {
//   // Simulate a network delay
//   await Future.delayed(const Duration(seconds: 1));
//   // In a real app, you would fetch this from your backend API
//   return mockRecentPrescriptions;
// });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digimeds/models/prescription_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digimeds/api/api_service.dart'; // Import your API service

// 1. User Name Provider
final userNameProvider = Provider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  // Try to get the Display Name, otherwise use the part of the email before '@'
  return user?.displayName ?? user?.email?.split('@').first ?? "User";
});

// 2. Recent Prescriptions Provider (Now fetches REAL data!)
final recentPrescriptionsProvider = FutureProvider<List<Prescription>>((
  ref,
) async {
  // This calls your backend endpoint: GET /prescriptions
  try {
    final prescriptions = await ApiService.getPrescriptions();

    // Sort them so the newest ones appear first (optional but looks better)
    // Assuming prescriptionDate is a string like "YYYY-MM-DD" or similar
    // If date format is inconsistent, you might skip sorting or parse carefully.
    return prescriptions.reversed.toList();
  } catch (e) {
    print("Error fetching prescriptions: $e");
    // Return an empty list instead of crashing if there's an error
    return [];
  }
});
