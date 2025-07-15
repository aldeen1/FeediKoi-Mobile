import 'package:flutter/material.dart';

class CurrentData{
  final DateTime timeStamp;
  final bool systemOn;
  final DateTime nextFeedETA;
  final double feedWeightKG;

  CurrentData({
    required this.timeStamp,
    required this.systemOn,
    required this.nextFeedETA,
    required this.feedWeightKG
  });
}

class FeedHistoryEntry {
  final DateTime time;
  final bool success;

  FeedHistoryEntry({
    required this.time,
    required this.success
  });
}

class FeedSettings {
  final TimeOfDay feedTime;
  final double weightLimitKG;
  final bool systemOn;

  FeedSettings({
    required this.feedTime,
    required this.weightLimitKG,
    required this.systemOn
  });
}

class InferenceResult {
  final String imageUrl;
  final Map<String, double> bboxCm;

  InferenceResult({
    required this.imageUrl,
    required this.bboxCm
  });
} 