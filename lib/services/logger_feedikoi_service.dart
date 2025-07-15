import 'package:flutter/material.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart';


class LoggingFeedikoiService implements FeedikoiService {
  final FeedikoiService _inner;

  LoggingFeedikoiService(this._inner);

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Stream<CurrentData> getCurrentDataStream() {
    print('[LOG] Subscribed to CurrentData stream');
    return _inner.getCurrentDataStream().map((data) {
      print('[LOG] CurrentData: $data');
      return data;
    });
  }

  @override
  Stream<List<FeedHistoryEntry>> getHistoryStream() {
    print('[LOG] Subscribed to History stream');
    return _inner.getHistoryStream().map((data) {
      print('[LOG] History Length: ${data.length}');
      for (var entry in data) {
        print('[LOG] Feed at ${entry.time}, success=${entry.success}');
      }
      return data;
    });
  }

  @override
  Stream<FeedSettings> getSettingsStream() {
    print('[LOG] Subscribed to Settings stream');
    return _inner.getSettingsStream().map((data) {
      print('[LOG] Settings: feedTime=${formatTimeOfDay(data.feedTime)}, '
          'weightLimitKG=${data.weightLimitKG}, systemOn=${data.systemOn}');
      return data;
    });
  }

  @override
  Stream<InferenceResult> getInferenceStream() {
    print('[LOG] Subscribed to Inference stream');
    return _inner.getInferenceStream().map((data) {
      print('[LOG] Inference Image URL: ${data.imageUrl}');
      return data;
    });
  }

  @override
  Stream<List<FishGrowthData>> getGrowthStream() {
    print('[LOG] Subscribed to Growth stream');
    return _inner.getGrowthStream().map((data) {
      print('[LOG] Growth Data Length: ${data.length}');
      return data;
    });
  }

  @override
  Future<void> toggleSystem(bool on) async {
    print('[LOG] toggleSystem called: $on');
    return _inner.toggleSystem(on);
  }

  @override
  Future<void> triggerFeedNow() async {
    print('[LOG] triggerFeedNow called');
    return _inner.triggerFeedNow();
  }

  @override
  Future<void> updateSettings(FeedSettings newSettings) async {
    print('[LOG] updateSettings called: '
        'feedTime=${formatTimeOfDay(newSettings.feedTime)}, '
        'weightLimitKG=${newSettings.weightLimitKG}, '
        'systemOn=${newSettings.systemOn}');
    return _inner.updateSettings(newSettings);
  }
}
