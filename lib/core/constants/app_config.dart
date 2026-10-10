const int kMaxChars = 600;
const double kHighConfidenceThreshold = 0.80;
const double kMediumConfidenceThreshold = 0.60;

const int translationStepCount = 3;

/// Languages the model has been trained and tested on.
/// Onhan (onh) and Asi (asi) have no training data yet.
const Set<String> kTranslatableLanguageIds = {'en', 'fil', 'ini'};

bool isPairSupported(String sourceId, String targetId) {
  return sourceId != targetId &&
      kTranslatableLanguageIds.contains(sourceId) &&
      kTranslatableLanguageIds.contains(targetId);
}