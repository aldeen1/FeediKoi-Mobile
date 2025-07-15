import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart';

class MockFeedikoiService implements FeedikoiService{
  final _currentCtrl = BehaviorSubject<CurrentData>();
  final _historyCtrl = BehaviorSubject<List<FeedHistoryEntry>>();
  final _settingsCtrl = BehaviorSubject<FeedSettings>();
  final _inferenceCtrl = BehaviorSubject<InferenceResult>();
  final _growthCtrl = BehaviorSubject<List<FishGrowthData>>();

  bool _systemOn = true;
  final List<FeedHistoryEntry> _history = [];
  final List<FishGrowthData> _growthData = [];
  FeedSettings _settings = FeedSettings(
    feedTime: TimeOfDay(hour: 8, minute: 0),
    weightLimitKG: 5.0,
    systemOn: true
  );

  MockFeedikoiService(){
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      final dayOffset = i ~/ 2;
      final hour = 8 + (i % 2) * 6; 
      _history.add(
        FeedHistoryEntry(
          time: now.subtract(Duration(days: dayOffset, hours: now.hour - hour)),
          success: i % 3 != 0,
        ),
      );
    }
    // Mock growth data (simulate 5 measurements)
    _growthData.addAll([
      FishGrowthData(day: 1, length: 8),
      FishGrowthData(day: 7, length: 12),
      FishGrowthData(day: 14, length: 16),
      FishGrowthData(day: 21, length: 19),
      FishGrowthData(day: 28, length: 23),
    ]);
    _growthCtrl.add(_growthData);
    _pushCurrent();
    _pushHistory();
    _settingsCtrl.add(_settings);
    _inferenceCtrl.add(
      InferenceResult(imageUrl: 'https://placekitten.com/400/300', bboxCm: {'koi': 23.0, 'weed': 10.1})
    );
  }

  Stream<List<FishGrowthData>> getGrowthStream() => _growthCtrl.stream;

  void _pushCurrent(){
    final now = DateTime.now();
    _currentCtrl.add(
        CurrentData(
            timeStamp: now,
            systemOn: _systemOn,
            nextFeedETA: now.add(const Duration(hours: 2)),
            feedWeightKG: 2.5 + (now.second % 3) 
        )
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
    final day = _growthData.isNotEmpty ? _growthData.last.day + 7 : 1;
    final length = inference.bboxCm['koi'] ?? 0;
    _growthData.add(FishGrowthData(day: day, length: length));
    _growthCtrl.add(List.from(_growthData));
  }
} 