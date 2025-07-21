import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRepository implements FeedikoiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Stream<CurrentData> getCurrentDataStream() {
    throw UnimplementedError();
  }

  @override
  Stream<List<FishGrowthData>> getGrowthStream() {
    // TODO: implement getGrowthStream
    throw UnimplementedError();
  }

  @override
  Stream<List<FeedHistoryEntry>> getHistoryStream() {
    return _database.ref('sensor_data').onValue.map((event) => CurrentData.fromMap(event.snapshot.value));
  }

  @override
  Stream<InferenceResult> getInferenceStream() {
    // TODO: implement getInferenceStream
    throw UnimplementedError();
  }

  @override
  Stream<FeedSettings> getSettingsStream() {
    // TODO: implement getSettingsStream
    throw UnimplementedError();
  }

  @override
  Future<void> toggleSystem(bool on) {
    // TODO: implement toggleSystem
    throw UnimplementedError();
  }

  @override
  Future<void> triggerFeedNow() {
    // TODO: implement triggerFeedNow
    throw UnimplementedError();
  }

  @override
  Future<void> updateSettings(FeedSettings newSettings) {
    // TODO: implement updateSettings
    throw UnimplementedError();
  }
  
}