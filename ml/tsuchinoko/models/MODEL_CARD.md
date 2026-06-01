# TsuchinokoCandidate.mlmodel

## Purpose

This is a prototype Core ML image classifier for `tsuchinoko_candidate` vs `not_tsuchinoko`.

It must not be used to claim that a real tsuchinoko was found. In an app, show results as "ツチノコ候補" or "UMA候補".

## Training Data

- Approved raw images: 17
- Augmented images: 3312
- Train: 3120
- Validation: 192
- Classes:
  - `tsuchinoko_candidate`
  - `not_tsuchinoko`

## Latest Training Run

- GitHub Actions run: `26756357252`
- Artifact: `TsuchinokoCandidate-CoreML`
- Artifact ID: `7332542038`
- Validation classification error: `0.03125`
- Validation accuracy estimate: `0.96875`

The validation set is still synthetic-heavy, so this score is only a smoke test.

## Evaluation Output

The workflow runs `scripts/evaluate_coreml.swift` after training.

- `models/evaluation.csv`: per-image expected label, predicted label, confidence, and correctness
- `models/evaluation.json`: summary counts, accuracy, false positives, and false negatives
- Latest evaluation: 192 validation images, 186 correct, 2 false positives, 4 false negatives
- `models/hard_examples`: copied false positives and false negatives for visual review

These files help find hard negatives and decide what field images to collect next.

Current hard examples suggest the model still needs more dim, monochrome, grass-occluded negatives and more grass-occluded thick-body positives.

## Next Data Needs

- More negative images from real outdoor camera footage
- Ordinary snakes in different lighting and angles
- Branches, hoses, ropes, roots, shadows, and wet leaves
- More tsuchinoko-style positives with different body thickness, colors, camera distances, and partial occlusion
