# AutoHarmonizer Plan (Pretrained — No Retraining)

## Objective

Use the **pretrained** AutoHarmonizer model to harmonize melodies. The repository already ships trained weights, so this plan drops all from-scratch training and instead builds a reproducible **inference** pipeline. OpenEWLD is used as a source of evaluation/demo melodies (not as training data). OpenBook remains optional.

## Status / Progress log

- **Milestone 1 — DONE.** The pretrained model runs end to end and produces harmonized output.
  - Repos cloned: `autoharmonizer/`, `OpenEWLD/`.
  - Split weight archive reassembled/extracted → `weights.hdf5` (26 MB). Shipped `inputs/inputs.zip` extracted (515 sample melodies).
  - Baseline run harmonized "Happy Birthday" → `outputs/…Happy Birthday.mxl` with `C, G, D7, G, D7, G, D7, G` (verified the chords re-parse with music21). ~7 s for one short song at ~10 ms/predict step.
- **Key deviation:** the original `linux/amd64` emulation plan (below) does **not** work on this host — see "Runtime" and the updated risk table. We ported to a **native arm64** runtime instead.
- **Next:** Milestone 2 (OpenEWLD melody-only inputs + `chord_types.bin` coverage check).

## Verified facts (grounding)

These were confirmed against the actual repositories before writing this plan:

- **AutoHarmonizer workflow** (from its README): put MusicXML in `dataset/` → `loader.py` builds `data_corpus.bin` → `model.py` trains `weights.hdf5` → `harmonizer.py` harmonizes melodies from `inputs/` into `outputs/`.
- **Pretrained artifacts already ship in the repo:** `weights.zip` + `weights.z01` (split archive of the trained weights), `data_corpus.zip` (prebuilt corpus), `dataset/dataset.zip` + `dataset.z01` (the original training data), and `chord_types.bin` (fixed chord vocabulary).
- **Inference is driven by `harmonizer.py` + `config.py`**, where `RHYTHM_DENSITY ∈ [0, 1]` controls harmonic density.
- **Upstream pinned dependencies (from README):** Python 3.7.9, Keras 2.3.0, keras-metrics 1.1.0, tensorflow-gpu 2.2.0 (CUDA 10.1), music21 6.7.1, tqdm 4.62.3, samplings 0.1.7. **Note:** we do NOT use these as-is — TF 2.2 has no arm64 wheels and crashes under x86 emulation on this host, so we run a modern TF (see Runtime).
- **OpenEWLD is derived from the old Wikifonia archive** — the *same* source AutoHarmonizer was originally trained on. It stores compressed MusicXML (`.mxl`) in a nested `dataset/<composer>/<score>/` layout. The SQLite metadata DB is named **`OpenEWLD.db`** in the cloned repo (the README calls it `EWLD.db`).
- **`config.py` `EXTENSION`** accepts `.musicxml`, `.xml`, and `.mxl`, and `loader.get_filenames` walks nested directories (`os.walk`), so OpenEWLD's nested layout can be read without flattening.
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

### 2. Unpack the shipped pretrained artifacts — DONE

The trained model is stored as a split zip archive, so recombine before extracting. This worked as written:

```bash
cd autoharmonizer
# Reassemble and extract the split weight archive
zip -s 0 weights.zip --out weights_full.zip && unzip -o weights_full.zip   # -> weights.hdf5 (26 MB)
# Sample melodies ship zipped inside inputs/
cd inputs && unzip -o inputs.zip && cd ..                                   # -> 515 .mxl files
unzip -o data_corpus.zip                                                    # -> data_corpus.bin (optional, unused for inference)
```

Validation (confirmed):

- `weights.hdf5` exists after extraction.
- `config.py`, `chord_types.bin`, `harmonizer.py`, `inputs/`, and `outputs/` are present.

### 3. Create an isolated inference runtime — DONE (revised approach)

Run it in Docker rather than on the host. **The original amd64-emulation plan failed and was replaced by a native arm64 runtime.**

What we tried first (did NOT work):

- Built `python:3.7.9-slim` `--platform linux/amd64` with CPU `tensorflow==2.2.0` and the other upstream pins. The image built fine (after dropping `apt` — Debian buster repos are archived and 404).
- But this host runs Docker via **colima on Apple Virtualization.Framework (aarch64) without Rosetta**, so amd64 images execute under **QEMU**, and **TensorFlow 2.2 hard-crashes at import**:
  `tensorflow/core/lib/monitoring/sampler.cc:42] Check failed: bucket_limits_[i] > bucket_limits_[i - 1]` — a known TF-under-QEMU bug. Not slowness; it cannot run there.

What works (current runtime):

- **Native arm64 image** (`python:3.10-slim`, no `--platform`), image tag `autoharmonizer:arm64`.
- **Modern TensorFlow with native aarch64 wheels:** `tensorflow==2.13.1`. This version still bundles **classic Keras 2.13** (not the breaking Keras 3), which keeps the functional-API model and weight loading compatible. Pins: `numpy==1.24.3`, `music21==6.7.1`, `tqdm==4.62.3`, `samplings==0.1.7`.
- **Code port to `tf.keras` (inference-only):** `model.py` and `harmonizer.py` were changed from standalone `keras` / `tensorflow.python.keras` imports to `tf.keras`, and `keras_metrics` (a training-only F1 metric) was removed from `model.compile`. Loading the old Keras 2.3 `weights.hdf5` into the modern-TF model via `load_weights` **worked with no shape mismatches**.

Build:

```bash
cd autoharmonizer
docker build -t autoharmonizer:arm64 .
```

### 4. Baseline run with the pretrained model — DONE

Confirm the runtime and weights work before touching any new data. Run inside the container with the source mounted at `/app`:

```bash
cd autoharmonizer
docker run --rm -v "$PWD":/app autoharmonizer:arm64 python -u harmonizer.py
```

Results (confirmed on a single staged melody, "Happy Birthday"):

- Produced `outputs/…Happy Birthday.mxl`; re-parsing with music21 shows 8 chord symbols: `C, G, D7, G, D7, G, D7, G` (a sensible G-major harmonization).
- Weights loaded cleanly into the ported `tf.keras` model (no shape errors).
- Performance: ~10 ms per `predict` step; ~7 s for one short song. Inference is a per-timestep `model.predict` loop, so batch runs over the full 515-song set are slow — **stage a small subset** for baseline/eval runs.

Remaining checks to do:

- Vary `RHYTHM_DENSITY` in `config.py` and confirm chord density changes.

### 5. Prepare OpenEWLD melodies as model inputs

Since we are harmonizing (not training), we want **melody-only** inputs, then we can compare the model's chords against OpenEWLD's original chords.

Handling notes:

- OpenEWLD is nested (`dataset/<composer>/<score>/*.mxl`); flattening into `inputs/` risks **filename collisions** across composers — prefix filenames (e.g. `<composer>__<score>.mxl`) or keep a manifest mapping.
- Use `music21==6.7.1` (same as `loader.py`) in any prep/validation script so parsing behavior matches the model's expectations.
- Strip existing chord symbols so the model harmonizes from scratch (keep the originals aside for comparison).

Suggested agent task:

- Write `scripts/prepare_openewld.py` that queries `OpenEWLD.db` (SQLite; note the actual filename), selects a subset, extracts melody-only MusicXML, writes to `inputs/`, and emits a CSV manifest (source path, new filename, metadata).
- Since `loader.get_filenames` walks nested dirs, you can alternatively point inputs at a nested subtree instead of flattening — but a flat, prefixed copy keeps output filenames unambiguous.

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
docker run --rm -v "$PWD":/app autoharmonizer:arm64 python -u harmonizer.py   # over the OpenEWLD-derived inputs/
```

Track at minimum:

- Dependency versions and platform (native arm64, `tensorflow==2.13.1`).
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

Done:

- ✅ `autoharmonizer/Dockerfile` — native arm64 inference runtime (`python:3.10-slim`, modern TF).
- ✅ `autoharmonizer/requirements.lock` — frozen deps (`tensorflow==2.13.1`, `numpy==1.24.3`, `music21==6.7.1`, `tqdm`, `samplings`).
- ✅ Code port of `model.py` / `harmonizer.py` to `tf.keras` (inference-only).

To do:

- `scripts/unpack_weights.sh` to reassemble/extract the split weight archive (currently done manually — see Step 2).
- `scripts/prepare_openewld.py` to select and extract melody-only inputs from `OpenEWLD.db`.
- `scripts/validate_inputs.py` for parsing checks and `chord_types.bin` coverage.
- `scripts/harmonize.sh` or `Makefile` targets to run the container over an input set.
- `logs/` folder for inference and validation outputs.
- `manifests/` folder with CSV manifests per input subset.
- `README` section documenting exact commands.

## Suggested Milestones

### Milestone 1: Pretrained model runs — ✅ DONE

- ✅ Docker image builds (native arm64, `autoharmonizer:arm64`).
- ✅ `weights.hdf5` extracted from the shipped split archive.
- ✅ `harmonizer.py` harmonizes a shipped `inputs/` sample into `outputs/` (verified chords re-parse).

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
| ~~amd64 emulation for TF 2.2~~ (CONFIRMED BLOCKER) | TF 2.2 crashes at import under QEMU (colima/VZ, no Rosetta) | **Resolved:** native arm64 image + modern `tensorflow==2.13.1` + code port to `tf.keras`. |
| Loading old Keras 2.3 weights into modern TF | Model won't load / wrong outputs | **Verified OK:** identical architecture + `load_weights` matched with no shape errors; outputs re-parse sensibly. |
| Modern TF pulling Keras 3 (TF ≥ 2.16) | Functional-API/weight-load breakage | Pin `tensorflow==2.13.1` (bundles classic Keras 2.13). |
| Split weight archive not reassembled correctly | No model to run | Use `zip -s 0 ... --out` then `unzip`; verify `weights.hdf5` exists. |
| OpenEWLD chords fall outside `chord_types.bin` | Model can't reproduce them | Check vocabulary coverage during input validation; set expectations accordingly. |
| Parser rejects some `.mxl` files | Reduces usable inputs | Validate and quarantine before the batch run. |
| OpenEWLD metadata bugs (time signature/key) | Incorrect filtering | Treat `metric`/`tonality` cautiously per the README's documented bugs. |
| Filename collisions when flattening nested inputs | Silent overwrites | Prefix with composer or keep a manifest mapping. |
| Style mismatch expectation (not jazzy) | Disappointed with output | Communicate up front: shared Wikifonia lineage means early-popular-song bias by design. |

## Recommended Starting Order

1. ✅ Clone repos and unpack the shipped pretrained weights.
2. ✅ Containerize the inference runtime (native arm64, modern TF).
3. ✅ Run `harmonizer.py` on a shipped sample input (baseline).
4. ⏭ Prepare a small OpenEWLD melody-only input set and validate it (Milestone 2).
5. ⏭ Harmonize and evaluate output quality across `RHYTHM_DENSITY` values.
6. Only then, optionally, prototype OpenBook conversion.

## Acceptance Criteria

- ✅ A fresh machine can reproduce the environment with Docker (native arm64 image; note: the runtime targets arm64 hosts — an x86 host would need a different TF build).
- ✅ The shipped pretrained model harmonizes melodies without manual per-file intervention beyond logged exclusions.
- ⏭ OpenEWLD melodies can be prepared and harmonized from scripts rather than manual copying.
- ⏭ Input subsets can be regenerated from scripts and manifests.
- OpenBook remains optional and isolated.
