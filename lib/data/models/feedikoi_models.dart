import 'package:cloud_firestore/cloud_firestore.dart';

class CurrentData {
  final String timeStamp;
  final bool systemOn;
  final FeedSettings feedSettings;
  final String location;
  final String namaKolam;

  CurrentData({
    required this.timeStamp,
    required this.systemOn,
    required this.feedSettings,
    required this.location,
    required this.namaKolam,
  });

  factory CurrentData.fromJson(Map<String, dynamic> json) {
    return CurrentData(
      timeStamp: (json['createdAt'] as Timestamp).toDate().toIso8601String(),
      systemOn: json['systemOn'],
      location: json['lokasi'],
      namaKolam: json['namaKolam'],
      feedSettings: FeedSettings.fromJson(json['feedSettings'] as Map<String, dynamic>),
    );
  }
}

class FeedSettings {
  final List<String> feedTime;
  final double weightLimitKG;

  FeedSettings({required this.feedTime, required this.weightLimitKG});

  factory FeedSettings.fromJson(Map<String, dynamic> json) {
    List<String> times = [];
    if (json['feedTime'] is Map) {
      final feedTimeMap = json['feedTime'] as Map<String, dynamic>;
      times = feedTimeMap.values.map((t) {
        if (t is Timestamp) {
          return t.toDate().toIso8601String();
        } else if (t is String) {
          return t;
        }
        return t.toString();
      }).toList();
    } else if (json['feedTime'] is List) {
      times = List<dynamic>.from(json['feedTime'])
          .map((t) {
            if (t is Timestamp) {
              return t.toDate().toIso8601String();
            } else if (t is String) {
              return t;
            }
            return t.toString();
          })
          .toList()
          .cast<String>();
    }

    return FeedSettings(
      feedTime: times,
      weightLimitKG: (json['weightLimitKG'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedTime': feedTime,
      'weightLimitKG': weightLimitKG,
    };
  }
}

class FeedHistoryEntry {
  final DateTime time;
  final bool success;

  FeedHistoryEntry({
    required this.time,
    required this.success,
  });

  factory FeedHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FeedHistoryEntry(
      time: (json['time'] as Timestamp).toDate(),
      success: json['success'],
    );
  }
}

class FishGrowthData {
  final DateTime date;
  final double length;
  final double weight;

  FishGrowthData({
    required this.date,
    required this.length,
    required this.weight,
  });

  factory FishGrowthData.fromJson(Map<String, dynamic> json) {
    return FishGrowthData(
      date: (json['date'] as Timestamp).toDate(),
      length: (json['length'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

class InferenceResult {
  final String imageUrl;
  final Map<String, double> bboxCm;

  InferenceResult({
    required this.imageUrl,
    required this.bboxCm,
  });

  factory InferenceResult.fromJson(Map<String, dynamic> json) {
    return InferenceResult(
      imageUrl: json['imageUrl'],
      bboxCm: Map<String, double>.from(json['bboxCm']),
    );
  }
} 