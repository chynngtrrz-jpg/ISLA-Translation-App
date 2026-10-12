const int kMaxChars = 600;
const double kHighConfidenceThreshold = 0.80;
const double kMediumConfidenceThreshold = 0.60;

const int translationStepCount = 3;

const bool kPhraseBookEnabled = true;
const double kFuzzyThreshold = 0.85;
const int kFuzzyMinLength = 4;
const bool kPhraseFallbackToModel = true; // false for a phrasebook-only demo
const bool kShowSuggestions = true;
const int kMaxSuggestions = 3;
const bool kShowResultSource = false; // true: show "From phrasebook/model"

bool isPairSupported(String sourceId, String targetId) {
  // TODO: restrict to translation directions trained and evaluated by the model.
  return sourceId != targetId;
}
