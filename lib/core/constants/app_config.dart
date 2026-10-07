const int kMaxChars = 600;
const double kHighConfidenceThreshold = 0.80;
const double kMediumConfidenceThreshold = 0.60;

const List<String> translationStepLabels = [
  'Choose Languages',
  'Input & Translate',
  'View Result',
];

bool isPairSupported(String sourceId, String targetId) {
  // TODO: restrict to translation directions trained and evaluated by the model.
  return sourceId != targetId;
}
