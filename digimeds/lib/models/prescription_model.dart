// import 'dart:convert';

// Prescription prescriptionFromJson(String str) =>
//     Prescription.fromJson(json.decode(str));

// class Prescription {
//   final String? patientName;
//   final String? doctorName;
//   final String? prescriptionDate;
//   final List<Medication> medications;

//   Prescription({
//     this.patientName,
//     this.doctorName,
//     this.prescriptionDate,
//     required this.medications,
//   });

//   factory Prescription.fromJson(Map<String, dynamic> json) {
//     var medList = json["medications"] as List? ?? [];
//     List<Medication> medicationObjects = medList
//         .map((i) => Medication.fromJson(i))
//         .toList();

//     return Prescription(
//       patientName: json["patientName"],
//       doctorName: json["doctorName"],
//       prescriptionDate: json["prescriptionDate"],
//       medications: medicationObjects,
//     );
//   }
// }

// class Medication {
//   final String? drugName;
//   final String? dosage;
//   final String? frequency;
//   final String? duration;

//   Medication({this.drugName, this.dosage, this.frequency, this.duration});

//   factory Medication.fromJson(Map<String, dynamic> json) {
//     return Medication(
//       drugName: json["drugName"],
//       dosage: json["dosage"],
//       frequency: json["frequency"],
//       duration: json["duration"],
//     );
//   }
// }

import 'dart:convert';

// Helper functions for JSON conversion
Prescription prescriptionFromJson(String str) =>
    Prescription.fromJson(json.decode(str));

String prescriptionToJson(Prescription data) => json.encode(data.toJson());

class Prescription {
  final String? id; // Optional Firestore ID
  final String? patientName;
  final String? doctorName;
  final String? prescriptionDate;
  final List<Medication> medications;

  Prescription({
    this.id,
    this.patientName,
    this.doctorName,
    this.prescriptionDate,
    required this.medications,
  });

  // Convert JSON from Backend -> Dart Object
  factory Prescription.fromJson(Map<String, dynamic> json) {
    var medList = json["medications"] as List? ?? [];
    List<Medication> medicationObjects = medList
        .map((i) => Medication.fromJson(i))
        .toList();

    return Prescription(
      id: json['id'],
      patientName: json["patientName"],
      doctorName: json["doctorName"],
      prescriptionDate: json["prescriptionDate"],
      medications: medicationObjects,
    );
  }

  // Convert Dart Object -> JSON for Backend (New!)
  Map<String, dynamic> toJson() => {
    "patientName": patientName,
    "doctorName": doctorName,
    "prescriptionDate": prescriptionDate,
    "medications": List<dynamic>.from(medications.map((x) => x.toJson())),
  };
}

class Medication {
  final String? drugName;
  final String? dosage;
  final String? frequency;
  final String? duration;

  Medication({this.drugName, this.dosage, this.frequency, this.duration});

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      drugName: json["drugName"],
      dosage: json["dosage"],
      frequency: json["frequency"],
      duration: json["duration"],
    );
  }

  // Convert Dart Object -> JSON (New!)
  Map<String, dynamic> toJson() => {
    "drugName": drugName,
    "dosage": dosage,
    "frequency": frequency,
    "duration": duration,
  };
}
