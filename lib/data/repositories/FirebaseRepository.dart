import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart' hide FishGrowthData;
import 'package:firebase_database/firebase_database.dart';

class FirebaseRepository implements FeedikoiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Stream<CurrentData> getCurrentDataStream() {
    final docRef = _firestore.collection("kolam").doc("kolam1");

    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return CurrentData.fromJson(data);
    });
  }

  @override
  Stream<List<FishGrowthData>> getGrowthStream() {
    final collectionRef = _firestore.collection("kolam/kolam1/fishGrowth");

    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FishGrowthData.fromJson(doc.data()))
          .toList();
    });
  }

  @override
  Stream<List<FeedHistoryEntry>> getHistoryStream() {
    final collectionRef = _firestore.collection("kolam/kolam1/feedHistory");

    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedHistoryEntry.fromJson(doc.data()))
          .toList();
    });
  }

  @override
  Stream<InferenceResult> getInferenceStream() {
    final docRef = _firestore.collection("kolam").doc("kolam1");
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Assuming 'inference' is a field in your 'kolam1' document
      return InferenceResult.fromJson(data['inference'] as Map<String, dynamic>);
    });
  }

  @override
  Stream<FeedSettings> getSettingsStream() {
    final docRef = _firestore.collection("kolam").doc("kolam1");
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FeedSettings.fromJson(data['feedSettings'] as Map<String, dynamic>);
    });
  }

  @override
  Future<void> updateSettings(FeedSettings newSettings) {
    final docRef = _firestore.collection("kolam").doc("kolam1");
    return docRef.update({'feedSettings': newSettings.toJson()});
  }

  @override
  Future<void> updateSystemStatus(bool systemOn) {
    final docRef = _firestore.collection("kolam").doc("kolam1");
    return docRef.update({'systemOn': systemOn});
  }
}