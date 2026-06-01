# TsuchinokoCandidate.mlmodel

## Purpose

This is a prototype Core ML image classifier for `tsuchinoko_candidate` vs `not_tsuchinoko`.

It must not be used to claim that a real tsuchinoko was found. In an app, show results as "ツチノコ候補" or "UMA候補".

## Training Data

- Approved raw images: 6
- Augmented images: 1056
- Train: 960
- Validation: 96
- Classes:
  - `tsuchinoko_candidate`
  - `not_tsuchinoko`

## Latest Training Run

- GitHub Actions run: `26749578617`
- Artifact: `TsuchinokoCandidate-CoreML`
- Artifact ID: `7329351590`
- Validation classification error: `0.44791666666666663`
- Validation accuracy estimate: `0.5520833333333334`

The validation set is still synthetic-heavy, so this score is only a smoke test.

## Next Data Needs

- More negative images from real outdoor camera footage
- Ordinary snakes in different lighting and angles
- Branches, hoses, ropes, roots, shadows, and wet leaves
- More tsuchinoko-style positives with different body thickness, colors, camera distances, and partial occlusion
