# TsuchinokoCandidate.mlmodel

## Purpose

This is a prototype Core ML image classifier for `tsuchinoko_candidate` vs `not_tsuchinoko`.

It must not be used to claim that a real tsuchinoko was found. In an app, show results as "ツチノコ候補" or "UMA候補".

## Training Data

- Approved raw images: 29
- Augmented images: 5808
- Train: 5520
- Validation: 288
- Classes:
  - `tsuchinoko_candidate`
  - `not_tsuchinoko`

## Latest Training Run

- GitHub Actions run: `26765841776`
- Artifact: `TsuchinokoCandidate-CoreML`
- Artifact ID: `7337211961`
- Validation classification error: `0.23263888888888884`
- Validation accuracy estimate: `0.7673611111111112`

The validation set is still synthetic-heavy, so this score is only a smoke test.

## Evaluation Output

The workflow runs `scripts/evaluate_coreml.swift` after training.

- `models/evaluation.csv`: per-image expected label, predicted label, confidence, and correctness
- `models/evaluation.json`: summary counts, accuracy, false positives, and false negatives
- Latest evaluation: 288 validation images, 231 correct, 45 false positives, 12 false negatives
- `models/hard_examples`: copied false positives and false negatives for visual review

These files help find hard negatives and decide what field images to collect next.

Current hard examples show the model still confuses some branch/root images with candidates. It now misses fewer positive candidates, but needs more hard negative field footage.

## Next Data Needs

- More negative images from real outdoor camera footage
- Ordinary snakes in different lighting and angles
- Branches, hoses, ropes, roots, shadows, and wet leaves
- More tsuchinoko-style positives with different body thickness, colors, camera distances, and partial occlusion
