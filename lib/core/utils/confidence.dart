import '../constants/app_config.dart';

enum ConfidenceLevel { high, medium, low }

ConfidenceLevel confidenceLevel(double confidence) {
  if (confidence >= kHighConfidenceThreshold) return ConfidenceLevel.high;
  if (confidence >= kMediumConfidenceThreshold) {
    return ConfidenceLevel.medium;
  }
  return ConfidenceLevel.low;
}
