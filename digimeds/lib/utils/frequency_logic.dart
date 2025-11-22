import 'package:flutter/material.dart';

class FrequencyLogic {
  static List<TimeOfDay> getTimesFromFrequency(String? frequency) {
    if (frequency == null) return [const TimeOfDay(hour: 9, minute: 0)];

    final lowerFreq = frequency.toLowerCase().trim();

    // --- REGEX PATTERNS FOR 1-0-1 STYLES ---

    // Pattern: 1-1-1 (Thrice)
    // Matches: 1-1-1, 1 1 1, 1.1.1
    if (RegExp(r'1[- .]1[- .]1').hasMatch(lowerFreq) ||
        lowerFreq.contains('thrice') ||
        lowerFreq.contains('tds') ||
        lowerFreq.contains('tid')) {
      return [
        const TimeOfDay(hour: 9, minute: 0), // Morning
        const TimeOfDay(hour: 14, minute: 0), // Afternoon
        const TimeOfDay(hour: 21, minute: 0), // Night
      ];
    }

    // Pattern: 1-0-1 (Twice)
    // Matches: 1-0-1, 1 0 1, 1-O-1
    if (RegExp(r'1[- .][0o][- .]1').hasMatch(lowerFreq) ||
        lowerFreq.contains('twice') ||
        lowerFreq.contains('bd') ||
        lowerFreq.contains('bid')) {
      return [
        const TimeOfDay(hour: 9, minute: 0), // Morning
        const TimeOfDay(hour: 21, minute: 0), // Night
      ];
    }

    // Pattern: 1-1-1-1 (4 times)
    if (RegExp(r'1[- .]1[- .]1[- .]1').hasMatch(lowerFreq) ||
        lowerFreq.contains('four') ||
        lowerFreq.contains('qid')) {
      return [
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 13, minute: 0),
        const TimeOfDay(hour: 17, minute: 0),
        const TimeOfDay(hour: 21, minute: 0),
      ];
    }

    // Pattern: 0-0-1 (Night only)
    if (RegExp(r'[0o][- .][0o][- .]1').hasMatch(lowerFreq) ||
        lowerFreq.contains('night') ||
        lowerFreq.contains('hs') ||
        lowerFreq.contains('bedtime')) {
      return [const TimeOfDay(hour: 21, minute: 0)];
    }

    // Pattern: 1-0-0 (Morning only)
    if (RegExp(r'1[- .][0o][- .][0o]').hasMatch(lowerFreq)) {
      return [const TimeOfDay(hour: 9, minute: 0)];
    }

    // Default Fallback
    return [const TimeOfDay(hour: 9, minute: 0)];
  }
}
