import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:rxdart/rxdart.dart';

class MockFeedikoiService implements FeedikoiService {
  final _currentCtrl = BehaviorSubject<CurrentData>();
  final _historyCtrl = BehaviorSubject<List<FeedHistoryEntry>>();
  final _settingsCtrl = BehaviorSubject<FeedSettings>();
  final _inferenceCtrl = BehaviorSubject<InferenceResult>();
  final _growthCtrl = BehaviorSubject<List<FishGrowthData>>();

  bool _systemOn = true;
  final List<FeedHistoryEntry> _history = [];
  final List<FishGrowthData> _growthData = [];

  FeedSettings _settings = FeedSettings(
    feedTime: ['08:00', '14:00'],
    weightLimitKG: 5.0,
  );

  MockFeedikoiService() {
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
    _growthData.addAll([
      FishGrowthData(
          date: DateTime.now().subtract(const Duration(days: 28)),
          length: 8,
          weight: 100),
      FishGrowthData(
          date: DateTime.now().subtract(const Duration(days: 21)),
          length: 12,
          weight: 150),
      FishGrowthData(
          date: DateTime.now().subtract(const Duration(days: 14)),
          length: 16,
          weight: 200),
      FishGrowthData(
          date: DateTime.now().subtract(const Duration(days: 7)),
          length: 19,
          weight: 250),
      FishGrowthData(date: DateTime.now(), length: 23, weight: 300),
    ]);
    _growthCtrl.add(_growthData);
    _pushCurrent();
    _pushHistory();
    _settingsCtrl.add(_settings);
    _inferenceCtrl.add(InferenceResult(
        imageUrl: 'https://placekitten.com/400/300',
        bboxCm: {'koi': 23.0, 'weed': 10.1}));
  }

  @override
  Stream<List<FishGrowthData>> getGrowthStream() => _growthCtrl.stream;

  void _pushCurrent() {
    _currentCtrl.add(CurrentData(
      timeStamp: DateTime.now().toIso8601String(),
      systemOn: _systemOn,
      feedSettings: _settings,
      location: 'Mock Location',
      namaKolam: 'Mock Kolam',
    ));
  }

  void _pushHistory() {
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
  Future<void> updateSettings(FeedSettings newSettings) async {
    _settings = newSettings;
    _settingsCtrl.add(_settings);
    _pushCurrent();
  }

  @override
  Future<void> updateSystemStatus(bool systemOn) async {
    _systemOn = systemOn;
    _pushCurrent();
  }

  void simulateInference(InferenceResult inference) {
    final length = inference.bboxCm['koi'] ?? 0;
    _growthData
        .add(FishGrowthData(date: DateTime.now(), length: length, weight: 0));
    _growthCtrl.add(List.from(_growthData));
  }
} 