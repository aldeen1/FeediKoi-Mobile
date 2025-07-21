import 'package:feedikoi/data/models/feedikoi_models.dart';

class FeedingTimeUtil {
  static Duration getTimeUntilNextFeeding(List<String> feedTimes) {
    if (feedTimes.isEmpty) return const Duration(minutes: 0);

    final now = DateTime.now();
    final todayFeedings = feedTimes.map((timeStr) {
      DateTime feedTime;
      try {
        feedTime = DateTime.parse(timeStr);
        return DateTime(
          now.year,
          now.month,
          now.day,
          feedTime.hour,
          feedTime.minute,
        );
      } catch (e) {
        try {
          final parts = timeStr.split(':');
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } catch (e) {
          return now;
        }
      }
    }).toList();

    final tomorrowFeedings = feedTimes.map((timeStr) {
      DateTime feedTime;
      try {
        feedTime = DateTime.parse(timeStr);
        return DateTime(
          now.year,
          now.month,
          now.day + 1,
          feedTime.hour,
          feedTime.minute,
        );
      } catch (e) {
        try {
          final parts = timeStr.split(':');
          return DateTime(
            now.year,
            now.month,
            now.day + 1,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } catch (e) {
          // If both fail, return current time (this feeding time will be ignored)
          return now.add(const Duration(days: 1));
        }
      }
    }).toList();

    final allFeedings = [...todayFeedings, ...tomorrowFeedings];
    allFeedings.sort();

    final nextFeeding = allFeedings.firstWhere(
      (time) => time.isAfter(now),
      orElse: () => todayFeedings.first.add(const Duration(days: 1)),
    );

    return nextFeeding.difference(now);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours jam ${minutes} menit';
    } else {
      return '$minutes menit';
    }
  }
} 