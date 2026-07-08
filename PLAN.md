# AutoHarmonizer Plan (Pretrained — No Retraining)

## Objective

Use the **pretrained** AutoHarmonizer model to harmonize melodies. The repository already ships trained weights, so this plan drops all from-scratch training and instead builds a reproducible **inference** pipeline. OpenEWLD is used as a source of evaluation/demo melodies (not as training data). OpenBook remains optional.

## Verified facts (grounding)

These were confirmed against the actual repositories before writing this plan:

- **AutoHarmonizer workflow** (from its README): put MusicXML in `dataset/` → `loader.py` builds `data_corpus.bin` → `model.py` trains `weights.hdf5` → `harmonizer.py` harmonizes melodies from `inputs/` into `outputs/`.
- **Pretrained artifacts already ship in the repo:** `weights.zip` + `weights.z01` (split archive of the trained weights), `data_corpus.zip` (prebuilt corpus), `dataset/dataset.zip` + `dataset.z01` (the original training data), and `chord_types.bin` (fixed chord vocabulary).
- **Inference is driven by `harmonizer.py` + `config.py`**, where `RHYTHM_DENSITY ∈ [0, 1]` controls harmonic density.
- **Pinned dependencies (from README):** Python 3.7.9, Keras 2.3.0, keras-metrics 1.1.0, tensorflow-gpu 2.2.0 (CUDA 10.1), music21 6.7.1, tqdm 4.62.3, samplings 0.1.7.
- **OpenEWLD is derived from the old Wikifonia archive** — the *same* source AutoHarmonizer was originally trained on. It stores compressed MusicXML (`.mxl`) in a nested `dataset/<composer>/<score>/` layout with an `EWLD.db` SQLite database of metadata.
- **Known OpenEWLD bugs (from its README):** no key signature is saved when it is set at the highest object hierarchy, and `getTimeSignatures()` returns `4/4` by default.

## Why we are not retraining

- **Trained weights already ship** (`weights.zip`), so a working model is available immediately.
- **OpenEWLD is a public-domain subset of the same Wikifonia data** the model was already trained on. Retraining on it would largely reproduce the original training distribution, so there is little upside and it is the most expensive, most failure-prone step.
- For a workshop, the fastest path to a working demo is the pretrained model plus good input melodies.

Corollary on musical style: because both the training data and OpenEWLD come from Wikifonia, outputs will lean toward **early popular song rather than modern jazz**. This is expected, not a bug. If a jazzier vocabulary is the goal, that realistically requires a *different* source (e.g. OpenBook) and would mean reintroducing training later — explicitly out of scope here.

## Target output

A reproducible, containerized inference pipeline that:

1. Provides a runtime compatible with the pretrained AutoHarmonizer.
2. Unpacks the shipped pretrained weights and supporting artifacts.
3. Runs `harmonizer.py` on sample melodies to confirm the model works end to end.
4. Feeds OpenEWLD-derived melodies through the model for evaluation/demo.
5. Optionally explores OpenBook melodies later.

## Implementation Steps

### 1. Clone repositories

```bash
git clone https://github.com/sander-wood/autoharmonizer
git clone https://github.com/00sapo/OpenEWLD
# optional later
git clone https://github.com/veltzer/openbook
```

### 2. Unpack the shipped pretrained artifacts

The trained model is stored as a split zip archive, so recombine before extracting.

```bash
cd autoharmonizer
# Reassemble and extract the split archives
zip -s 0 weights.zip --out weights_full.zip && unzip -o weights_full.zip   # -> weights.hdf5
unzip -o data_corpus.zip                                                    # -> data_corpus.bin (optional)
```

Validation:

- Confirm `weights.hdf5` exists after extraction.
- Confirm `config.py`, `chord_types.bin`, `harmonizer.py`, `inputs/`, and `outputs/` are present.

### 3. Create an isolated inference runtime

AutoHarmonizer pins old Python/ML versions, so run it in Docker rather than on the host.

Environment constraints to plan for explicitly:

- The host is Apple Silicon macOS with **no NVIDIA GPU**, so replace `tensorflow-gpu==2.2.0` with the **CPU** `tensorflow==2.2.0`.
- TF 2.2.0 has no arm64 wheels, so build/run the image as **`--platform linux/amd64`** (x86 emulation; slower but functional). CPU-only inference is fine for a workshop-scale run.

Suggested agent task:

- Create a `Dockerfile` inside `autoharmonizer/` based on `python:3.7.9` (linux/amd64).
- Install the pinned versions above, substituting CPU TensorFlow.
- Mount both the `autoharmonizer/` and `OpenEWLD/` directories as volumes.

### 4. Baseline run with the pretrained model

Confirm the runtime and weights work before touching any new data.

```bash
cd autoharmonizer
python harmonizer.py   # harmonizes melodies in inputs/ -> outputs/
```

Checks:

- The shipped example melodies in `inputs/` produce harmonized files in `outputs/`.
- Vary `RHYTHM_DENSITY` in `config.py` and confirm chord density changes.
- Record runtime and any warnings. This is the true first milestone.

### 5. Prepare OpenEWLD melodies as model inputs

Since we are harmonizing (not training), we want **melody-only** inputs, then we can compare the model's chords against OpenEWLD's original chords.

Handling notes:

- OpenEWLD is nested (`dataset/<composer>/<score>/*.mxl`); flattening into `inputs/` risks **filename collisions** across composers — prefix filenames (e.g. `<composer>__<score>.mxl`) or keep a manifest mapping.
- Use `music21==6.7.1` (same as `loader.py`) in any prep/validation script so parsing behavior matches the model's expectations.
- Strip existing chord symbols so the model harmonizes from scratch (keep the originals aside for comparison).

Suggested agent task:

- Write `scripts/prepare_openewld.py` that queries `EWLD.db`, selects a subset, extracts melody-only MusicXML, writes to `inputs/`, and emits a CSV manifest (source path, new filename, metadata).

### 6. Validate input compatibility

Before a batch run, verify the selected melodies actually parse and are within the model's vocabulary.

Agent checklist:

- Confirm `.mxl`/`.xml`/`.musicxml` inputs parse with `music21`.
- Confirm melody parses successfully and note where chord symbols were stripped.
- **Check chord coverage against `chord_types.bin`** — the model uses a fixed chord vocabulary, so compare OpenEWLD's original chord qualities to it to understand what the model can and cannot reproduce.
- Quarantine/log any file that fails to parse instead of failing the whole batch.
- Treat OpenEWLD's `metric` and `tonality` metadata cautiously due to the documented time-signature/key bugs.

### 7. Harmonize OpenEWLD melodies

```bash
cd autoharmonizer
python harmonizer.py   # over the OpenEWLD-derived inputs/
```

Track at minimum:

- Dependency versions and platform (amd64 emulation).
- Input subset name and count.
- `RHYTHM_DENSITY` value(s) used.
- Output files produced and any skipped inputs.

### 8. Evaluate musical usefulness

Listen early; don't over-engineer the input set first.

Recommended evaluation set:

- 5 simple standards-like melodies.
- 5 rhythmically denser melodies.
- 5 melodies outside the main (Wikifonia) style.

Record observations:

- Chord vocabulary richness.
- Tonal stability and cadence quality.
- Repetition or mode collapse.
- Whether outputs sound closer to early popular song than modern jazz (expected — see Objective).
- Where the model's chords agree/differ from OpenEWLD's originals.

### 9. Optional: explore OpenBook melodies

Only if a jazzier vocabulary is needed. Because OpenBook is LilyPond-based, it requires conversion to MusicXML before it can be used as input.

Recommended prototype process:

1. Select 5–10 representative OpenBook tunes.
2. Export to MusicXML via the best available LilyPond path.
3. Parse with `music21` and confirm melody survives.
4. Harmonize with the pretrained model and compare against the source charts.

Note: getting genuinely jazzier *output* (not just jazzier input melodies) would require retraining on jazz data, which is out of scope for this pretrained-only plan.

## Deliverables for the Coding Agent

- `Dockerfile` for the AutoHarmonizer inference runtime (linux/amd64, CPU TensorFlow).
- `requirements.lock` or equivalent frozen dependency list (with CPU `tensorflow==2.2.0`).
- `scripts/unpack_weights.sh` to reassemble/extract the split weight archive.
- `scripts/prepare_openewld.py` to select and extract melody-only inputs from `EWLD.db`.
- `scripts/validate_inputs.py` for parsing checks and `chord_types.bin` coverage.
- `scripts/harmonize.sh` or `Makefile` targets to run `harmonizer.py` over an input set.
- `logs/` folder for inference and validation outputs.
- `manifests/` folder with CSV manifests per input subset.
- `README` section documenting exact commands.

## Suggested Milestones

### Milestone 1: Pretrained model runs

- Docker image builds (linux/amd64).
- `weights.hdf5` extracted from the shipped split archive.
- `harmonizer.py` harmonizes the shipped `inputs/` samples into `outputs/`.

### Milestone 2: OpenEWLD inputs work

- Melody-only inputs extracted from OpenEWLD into `inputs/` (with collision-safe names).
- Random samples parse with `music21`.
- Chord coverage checked against `chord_types.bin`.

### Milestone 3: Evaluation done

- Evaluation set harmonized across at least two `RHYTHM_DENSITY` values.
- Failed inputs tracked and excluded automatically.
- Qualitative notes recorded.

### Milestone 4 (optional): OpenBook exploration

- A small LilyPond→MusicXML conversion validated.
- OpenBook melodies harmonized and compared to source charts.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Old ML dependencies break on modern/Apple Silicon systems | Blocks inference | Docker `--platform linux/amd64` with pinned versions and CPU `tensorflow==2.2.0`. |
| Split weight archive not reassembled correctly | No model to run | Use `zip -s 0 ... --out` then `unzip`; verify `weights.hdf5` exists. |
| OpenEWLD chords fall outside `chord_types.bin` | Model can't reproduce them | Check vocabulary coverage during input validation; set expectations accordingly. |
| Parser rejects some `.mxl` files | Reduces usable inputs | Validate and quarantine before the batch run. |
| OpenEWLD metadata bugs (time signature/key) | Incorrect filtering | Treat `metric`/`tonality` cautiously per the README's documented bugs. |
| Filename collisions when flattening nested inputs | Silent overwrites | Prefix with composer or keep a manifest mapping. |
| Style mismatch expectation (not jazzy) | Disappointed with output | Communicate up front: shared Wikifonia lineage means early-popular-song bias by design. |

## Recommended Starting Order

1. Clone repos and unpack the shipped pretrained weights.
2. Containerize the inference runtime (linux/amd64, CPU TF).
3. Run `harmonizer.py` on the shipped sample inputs (baseline).
4. Prepare a small OpenEWLD melody-only input set and validate it.
5. Harmonize and evaluate output quality across `RHYTHM_DENSITY` values.
6. Only then, optionally, prototype OpenBook conversion.

## Acceptance Criteria

- A fresh machine can reproduce the environment with Docker.
- The shipped pretrained model harmonizes melodies without manual per-file intervention beyond logged exclusions.
- OpenEWLD melodies can be prepared and harmonized from scripts rather than manual copying.
- Input subsets can be regenerated from scripts and manifests.
- OpenBook remains optional and isolated.
