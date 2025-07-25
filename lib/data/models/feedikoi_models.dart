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
    print("Feed settings data: $json");
    if (json['feedTime'] is Map) {
      final feedTimeMap = json['feedTime'] as Map<String, dynamic>;
      print("Feed time map: $feedTimeMap");
      times = feedTimeMap.values.map((t) {
        if (t is Timestamp) {
          return t.toDate().toIso8601String();
        } else if (t is String) {
          if (t.length == 5 && t.contains(':')) {
            final now = DateTime.now();
            final parts = t.split(':');
            final time = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            return time.toIso8601String();
          }
          return t;
        }
        return t.toString();
      }).toList();
    } else if (json['feedTime'] is List) {
      print("Feed time list: ${json['feedTime']}");
      times = List<dynamic>.from(json['feedTime'])
          .map((t) {
            if (t is Timestamp) {
              return t.toDate().toIso8601String();
            } else if (t is String) {
              if (t.length == 5 && t.contains(':')) {
                final now = DateTime.now();
                final parts = t.split(':');
                final time = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
                return time.toIso8601String();
              }
              return t;
            }
            return t.toString();
          })
          .toList()
          .cast<String>();
    }
    print("Parsed feed times: $times");

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

  factory FeedHistoryEntry.fromJson(Map<String, dynamic> json, FeedSettings settings) {
    print("Parsing history entry: $json");
    print("Feed settings times: ${settings.feedTime}");
    
    final time = DateTime.parse(json['time'] as String);
    
    bool success = false;
    for (String feedTime in settings.feedTime) {
      try {
        DateTime parsedFeedTime;
        if (feedTime.length == 5 && feedTime.contains(':')) {
          final parts = feedTime.split(':');
          parsedFeedTime = DateTime(
            time.year,
            time.month,
            time.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          parsedFeedTime = DateTime.parse(feedTime);
        }
        
        if (parsedFeedTime.hour == time.hour && parsedFeedTime.minute == time.minute) {
          success = true;
          break;
        }
      } catch (e) {
        print("Error parsing feed time: $feedTime, Error: $e");
        continue;
      }
    }
    
    return FeedHistoryEntry(
      time: time,
      success: success,
    );
  }

  factory FeedHistoryEntry.fromJsonWithSuccess(Map<String, dynamic> json) {
    print("Parsing history entry with stored success: $json");
    
    final time = DateTime.parse(json['time'] as String);
    final success = json['success'] as bool;
    
    return FeedHistoryEntry(
      time: time,
      success: success,
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