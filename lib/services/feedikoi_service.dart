import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

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

abstract class FeedikoiService{
  Stream<CurrentData> getCurrentDataStream();
  Stream<List<FeedHistoryEntry>> getHistoryStream();
  Stream<FeedSettings> getSettingsStream();
  Stream<InferenceResult> getInferenceStream();

  Future<void> updateSettings(FeedSettings newSettings);
  Future<void> triggerFeedNow();
  Future<void> toggleSystem(bool on);
}

class MockFeedikoiService implements FeedikoiService{
  //Controllers
  final _currentCtrl = BehaviorSubject<CurrentData>();
  final _historyCtrl = BehaviorSubject<List<FeedHistoryEntry>>();
  final _settingsCtrl = BehaviorSubject<FeedSettings>();
  final _inferenceCtrl = BehaviorSubject<InferenceResult>();

  bool _systemOn = true;
  final List<FeedHistoryEntry> _history = [];
  FeedSettings _settings = FeedSettings(
    feedTime: TimeOfDay(hour: 8, minute: 0),
    weightLimitKG: 5.0,
    systemOn: true
  );

  MockFeedikoiService(){
    _history.addAll([
      FeedHistoryEntry(time: DateTime.now().subtract(Duration(hours: 3)), success: true),
      FeedHistoryEntry(time: DateTime.now().subtract(Duration(hours: 5)), success: false),
      FeedHistoryEntry(time: DateTime.now().subtract(Duration(days: 1)), success: true),
    ]);
    _pushCurrent();
    _pushHistory();
    _settingsCtrl.add(_settings);
    _inferenceCtrl.add(
      InferenceResult(imageUrl: 'https://placekitten.com/400/300', bboxCm: {'koi': 50.2, 'weed': 10.1})
    );
  }

  void _pushCurrent(){
    final now = DateTime.now();
    _currentCtrl.add(
        CurrentData(
            timeStamp: now,
            systemOn: true,
            nextFeedETA: now.add(const Duration(hours: 2)),
            feedWeightKG: 3.5)
    );
  }
  void _pushHistory(){
    _historyCtrl.add(_history);
  }


  @override
  Stream<CurrentData> getCurrentDataStream() => _currentCtrl.stream;

  @override
  Stream<List<FeedHistoryEntry>> getHistoryStream() => _historyCtrl.stream;

  @override
  Stream<InferenceResult> getInferenceStream() => _inferenceCtrl.stream;

  @override
  Stream<FeedSettings> getSettingsStream() => _settingsCtrl.stream;

  @override
  Future<void> toggleSystem(bool on) async {
    _systemOn = on;
    _pushCurrent();
  }

  @override
  Future<void> triggerFeedNow() async {
    final now = DateTime.now();
    final entry = FeedHistoryEntry(time: now, success: true);
    _history.add(entry);
    _pushHistory();
    _pushCurrent();
  }

  @override
  Future<void> updateSettings(FeedSettings newSettings) async {
    _settings = newSettings;
    _settingsCtrl.add(_settings);
    _systemOn = newSettings.systemOn;
    _pushCurrent();
  }

  void simulateInference(InferenceResult inference){
    _inferenceCtrl.add(inference);
  }
}