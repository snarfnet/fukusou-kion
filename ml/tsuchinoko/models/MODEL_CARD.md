# TsuchinokoCandidate.mlmodel

## Purpose

This Core ML image classifier separates `tsuchinoko_candidate` from `not_tsuchinoko`.

The app must not claim that a real tsuchinoko was found. It should show the result as a candidate score and notify only when the app sees a strong, repeated candidate.

## Training Data

- Approved raw images before augmentation: 122
- Shape-focused raw images added in this revision: 77
- Projected augmented images for the next training set: 3534
- Classes:
  - `tsuchinoko_candidate`
  - `not_tsuchinoko`

The manifest uses a fixed `split` column so hard-example additions do not randomly change the validation set.

## Latest Training Run

- GitHub Actions run: `26816367982`
- Artifact: `TsuchinokoCandidate-CoreML`
- Model: `models/TsuchinokoCandidate.mlmodel`
- App bundle copy: `ios/TsuchinokoFinder/TsuchinokoFinder/Models/TsuchinokoCandidate.mlmodel`

## Evaluation Output

The workflow runs `scripts/evaluate_coreml.swift` after training.

- `models/evaluation.csv`: per-image expected label, predicted label, confidence, and correctness
- `models/evaluation.json`: summary counts, accuracy, false positives, and false negatives
- `models/hard_examples`: copied false positives and false negatives for visual review

Latest evaluation:

- Total validation images: 144
- Correct: 109
- Accuracy: `0.7569444444444444`
- False positives: 15
- False negatives: 20

The previous model had 45 false positives and 12 false negatives on its evaluation set. This revision intentionally moves the app toward fewer false alerts. It may miss more weak candidates, but it should be less eager to call branches, vines, hoses, or ordinary snake-like shapes a tsuchinoko candidate.

The validation set is still synthetic-heavy, so these numbers are a smoke test, not proof of field performance.

## What Changed

This revision adds shape-focused examples:

- Positive examples emphasize a short, thick body, low posture, visible head/body balance, and a grounded silhouette.
- Negative examples emphasize long thin snakes, branches, vines, hoses, roots, and line-like objects.

The app also applies stricter candidate logic:

- Higher default threshold
- Repeated candidate frames before alerting
- Motion-based gating so a single static frame is less likely to trigger

## Next Data Needs

- Real trail camera negatives from the intended environment
- Ordinary snakes in more lighting, angles, and distances
- Branches, hoses, ropes, roots, wet leaves, and shadows that look close to candidates
- More tsuchinoko-style positives with varied thickness, color, camera distance, partial occlusion, and body direction
