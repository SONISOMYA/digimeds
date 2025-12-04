import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digimeds/models/prescription_model.dart';
import 'package:digimeds/api/api_service.dart';
import 'package:digimeds/utils/frequency_logic.dart';
import 'package:digimeds/services/notification_service.dart'; // Import NotificationService

class ReviewScreen extends StatelessWidget {
  final Prescription prescription;

  const ReviewScreen({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Scanned Prescription",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildInfoCard("Patient Name", prescription.patientName, context),
          _buildInfoCard("Doctor Name", prescription.doctorName, context),
          _buildInfoCard("Date", prescription.prescriptionDate, context),
          const SizedBox(height: 24),
          Text(
            "Medications",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Display each medication in its own modern card
          for (var med in prescription.medications) ...[
            _buildMedicationCard(med, context),
            const SizedBox(height: 12),
          ],
        ],
      ),
      // Floating Action Button to save the prescription
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving to history...')),
              );

              await ApiService.savePrescription(prescription);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save to History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Helper widget for patient/doctor info
  Widget _buildInfoCard(String title, String? value, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
          ),
          Text(
            value ?? 'Not found',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Helper widget for medication info (UPDATED WITH NOTIFICATION BUTTON)
  Widget _buildMedicationCard(Medication med, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  med.drugName ?? 'Unknown Drug',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              // --- NOTIFICATION BELL ICON ---
              IconButton(
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.orange,
                ),
                tooltip: "Set Reminder",
                onPressed: () async {
                  // Show the smart dialog
                  final bool? success = await showDialog(
                    context: context,
                    builder: (context) => ScheduleDialog(med: med),
                  );

                  if (success == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminders set for ${med.drugName}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Dosage: ${med.dosage ?? 'N/A'}",
                  style: GoogleFonts.inter(),
                ),
              ),
              Expanded(
                child: Text(
                  "Frequency: ${med.frequency ?? 'N/A'}",
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Duration: ${med.duration ?? 'N/A'}",
            style: GoogleFonts.inter(),
          ),
        ],
      ),
    );
  }
}

// --- Smart Schedule Dialog ---
class ScheduleDialog extends StatefulWidget {
  final Medication med;
  const ScheduleDialog({super.key, required this.med});

  @override
  State<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  late List<TimeOfDay> _scheduledTimes;

  @override
  void initState() {
    super.initState();
    // 1. Auto-generate times based on the AI extracted frequency
    _scheduledTimes = FrequencyLogic.getTimesFromFrequency(
      widget.med.frequency,
    );
  }

  Future<void> _editTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTimes[index],
    );
    if (picked != null) {
      setState(() {
        _scheduledTimes[index] = picked;
      });
    }
  }

  void _saveReminders() {
    // 2. Loop through all times and schedule them
    for (int i = 0; i < _scheduledTimes.length; i++) {
      // Create a unique ID for each slot: HashCode + Index
      // Handle null drugName gracefully
      int uniqueId = (widget.med.drugName ?? 'unknown').hashCode + i;

      NotificationService().scheduleDailyNotification(
        id: uniqueId,
        title: "Time for ${widget.med.drugName ?? 'Medicine'}",
        body: "Take your dose. (${widget.med.dosage ?? 'As prescribed'})",
        time: _scheduledTimes[i],
      );
    }

    Navigator.of(context).pop(true); // Return true to indicate success
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Schedule ${widget.med.drugName ?? 'Medicine'}"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Frequency detected: ${widget.med.frequency ?? 'Unknown'}\nWe have suggested the following times:",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // 3. Dynamic list of times
            ListView.builder(
              shrinkWrap: true,
              itemCount: _scheduledTimes.length,
              itemBuilder: (context, index) {
                final time = _scheduledTimes[index];
                return ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.blue),
                  title: Text(
                    time.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit, size: 16),
                  onTap: () => _editTime(index), // Tap to change default
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saveReminders,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Confirm & Set"),
        ),
      ],
    );
  }
}
