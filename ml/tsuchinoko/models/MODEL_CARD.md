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

- GitHub Actions run: `26754037593`
- Artifact: `TsuchinokoCandidate-CoreML`
- Artifact ID: `7331562935`
- Validation classification error: `0.09375`
- Validation accuracy estimate: `0.90625`

The validation set is still synthetic-heavy, so this score is only a smoke test.

## Next Data Needs

- More negative images from real outdoor camera footage
- Ordinary snakes in different lighting and angles
- Branches, hoses, ropes, roots, shadows, and wet leaves
- More tsuchinoko-style positives with different body thickness, colors, camera distances, and partial occlusion
