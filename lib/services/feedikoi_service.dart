// FeedikoiService interface for dependency injection and clean architecture.
// Do not put any implementation here. Implementations should be in data/repository or similar.
import 'package:feedikoi/data/models/feedikoi_models.dart';
import 'package:feedikoi/shared/widgets/fish_growth_line_chart.dart' hide FishGrowthData;

abstract class FeedikoiService {
  Stream<CurrentData> getCurrentDataStream();
  Stream<List<FeedHistoryEntry>> getHistoryStream();
  Stream<FeedSettings> getSettingsStream();
  Stream<InferenceResult> getInferenceStream();
  Stream<List<FishGrowthData>> getGrowthStream();
  Stream<double> getCurrentWeightStream();

  Future<void> updateSettings(FeedSettings newSettings);
  Future<void> updateSystemStatus(bool systemOn);
}