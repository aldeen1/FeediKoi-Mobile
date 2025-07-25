import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart' hide FishGrowthData;
import 'package:firebase_database/firebase_database.dart';

class FirebaseRepository implements FeedikoiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  FirebaseRepository() {
    _database.databaseURL = 'https://feedikoi-project-default-rtdb.asia-southeast1.firebasedatabase.app';
  }

  @override
  Stream<double> getCurrentWeightStream() {
    return _database.ref("device1/weight").onValue.map((event) {
        print('Received weight event: ${event.snapshot.value}');
      if (event.snapshot.value == null) {
        print('Weight value is null');
        return 0.0;
      }
      
      try {
        final Map<Object?, Object?> data = event.snapshot.value as Map<Object?, Object?>;
        final weight = (data['value'] as num).toDouble();
        print('Parsed weight: $weight');
        return weight;
      } catch (e) {
        print('Error parsing weight: $e');
        return 0.0;
      }
    });
  }

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
    final docRef = _firestore.collection("kolam").doc("kolam1");

    return docRef.snapshots().asyncMap((docSnapshot) async {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final feedSettings = FeedSettings.fromJson(data['feedSettings']);

      final historyRef = _database.ref("device1/logs");
      final historySnapshot = await historyRef.get();

      final List<FeedHistoryEntry> historyEntries = [];
      final List<Future<void>> updateTasks = [];

      for (var child in historySnapshot.children) {
        if (child.key == 'weight') continue;

        print("History snapshot's child : ${child.value}");

        try {
          final snap = child.value as Map<dynamic, dynamic>;
          final timeStr = snap['time'] as String;
          final childKey = child.key!;
          
          bool? storedSuccess = snap['success'] as bool?;
          
          if (storedSuccess != null) {
            print('Using stored success value for entry $childKey: $storedSuccess');
            final Map<String, dynamic> historyData = {
              'time': timeStr,
              'success': storedSuccess,
            };
            historyEntries.add(FeedHistoryEntry.fromJsonWithSuccess(historyData));
          } else {
            print('Calculating and storing success value for entry $childKey');
            final Map<String, dynamic> historyData = {
              'time': timeStr,
            };
            
            final entry = FeedHistoryEntry.fromJson(historyData, feedSettings);
            historyEntries.add(entry);
            
            final updateTask = _database.ref("device1/logs/$childKey").update({
              'success': entry.success,
            }).catchError((error) {
              print('Error updating success field for entry $childKey: $error');
            });
            
            updateTasks.add(updateTask);
          }
        } catch (e) {
          print('Error parsing history entry: $e');
          print(child.value);
          continue;
        }
      }

      if (updateTasks.isNotEmpty) {
        Future.wait(updateTasks).then((_) {
          print('Successfully updated ${updateTasks.length} entries with success values');
        }).catchError((error) {
          print('Some database updates failed: $error');
        });
      }

      historyEntries.sort((a, b) => b.time.compareTo(a.time));
      return historyEntries;
    });
  }

  @override
  Stream<InferenceResult> getInferenceStream() {
    final docRef = _firestore.collection("kolam").doc("kolam1");
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
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