# Max + Python OSC Chord Generator Plan

This document is the **canonical specification** for a Max device that communicates with a Python service over OSC/UDP to transform one input chord into one output chord.

- **Protocol v1** (implemented): first-order Markov chain from CSV.
- **Protocol v2** (planned): adds JazzNet RNN and LSTM models as selectable backends, with Max-side model switcher.

Current default remains Markov for backward compatibility.

## Objective

Build a small system with three clear responsibilities:

- Max handles user interaction, testing UX, and downstream musical integration.
- Python handles CSV loading, Markov transition lookup, weighted sampling, validation, and reply messaging.
- OSC over UDP provides loose coupling between both processes.

The implementation should favor simple local operation on one machine first, using `127.0.0.1` and fixed ports, then leave room for later extension to remote hosts or multiple clients.

## Scope

### In scope

- One input chord symbol, one generated output chord symbol.
- First-order Markov chain based on `chord_from -> chord_to` transitions from CSV.
- Bidirectional OSC messaging between Max and Python.
- Error reporting, startup signaling, logging, and manual test controls.
- Validation checkpoints so the coding agent can stop, verify, and correct issues before continuing.

### Out of scope for v1

- Higher-order Markov chains.
- Harmonic parsing beyond string labels.
- Audio rendering in Python.
- Multi-user networking or binding to `0.0.0.0`.
- Full DAW packaging or installer generation.
- Max for Live device packaging (v1 is a standalone `.maxpat` for Max/MSP).

## Assumptions

- The Markov CSV already exists and follows the schema `chord_from,chord_to,count,probability`.
- Default data file: `data/markov_openbook.csv` (copied or symlinked from repo-root `markov_openbook.csv`). A smaller smoke-test file `data/chord_progressions_transitions.csv` may be used during early development.
- Chord labels such as `G:7` and `C:maj7` are treated as opaque tokens in v1.
- Max and Python run on the same machine during initial development.
- Python binds only to `127.0.0.1` in v1.
- UDP message loss is acceptable for v1, but visible status, timeouts, and retry-friendly behavior are still required.

## Proposed architecture

### Components

1. **Max patch (`max/chord_generator_device.maxpat`)**
   - Standalone Max/MSP patch (not Max for Live in v1).
   - Receives or captures an input chord.
   - Sends OSC to Python.
   - Receives OSC reply from Python.
   - Displays status, error, and generated chord.
   - Optionally forwards output to MIDI or other Max logic.

2. **Python service**
   - Loads and validates the CSV.
   - Builds in-memory transition tables grouped by `chord_from`.
   - Runs an OSC server to receive chord requests.
   - Runs an OSC client to send replies back to Max using `python-osc`.

3. **CSV data source**
   - Stores transition counts and probabilities.
   - Is loaded at startup and optionally reloadable by command.

### Communication model

Use separate ports for each direction so each side has one listening socket and one sending target.

Default local configuration:

| Setting | Value | Notes |
|---|---|---|
| Host | `127.0.0.1` | Same-machine development default; do not bind `0.0.0.0` in v1. |
| Python receive port | `9000` | Max sends requests here. |
| Max receive port | `9001` | Python sends replies here. |
| Transport | UDP / OSC | Max uses CNMAT OSC objects; Python uses `python-osc`. |
| Reply timeout | `500 ms` | Max waits this long for `/chord/output` before showing a timeout error. |

### Startup and readiness (default)

Avoid relying on a one-shot `/status/ready` broadcast at Python startup, because Max may not be listening yet.

Default readiness flow:

1. Python loads CSV, opens its OSC server on `127.0.0.1:9000`, then sends `/status/ready` with payload `1` (best effort).
2. Max opens `udpreceive` on port `9001`, then sends `/control/ping` (no arguments).
3. Python replies with `/status/pong` payload `1`.
4. Max sets its status indicator to **ready** on first `/status/pong` or `/status/ready`.
5. After Python restart, Max re-sends `/control/ping` to re-establish readiness.

## OSC contract

Define the protocol before implementation. **`PLAN.md` is the canonical contract**; `docs/osc_contract.md` may mirror it but must not diverge.

### Example message trace

```text
Max  -> Python:  /chord/input   s  "G:7"
Python -> Max:   /chord/output  s  "C:maj"
Python -> Max:   /debug/probability  f  0.462
Python -> Max:   /debug/candidates   i  18
Python -> Max:   /debug/input_echo   s  "G:7"
Python -> Max:   /debug/fallback_used i  0
```

### Required addresses

| Direction | OSC address | Payload | Purpose |
|---|---|---|---|
| Max -> Python | `/chord/input` | `string` | Request next chord from current chord. |
| Python -> Max | `/chord/output` | `string` | Return selected next chord. |
| Python -> Max | `/status/ready` | `int` (`1`) | Signal service startup success (best effort). |
| Python -> Max | `/error` | `string` | Report recoverable errors. |
| Max -> Python | `/control/ping` | _(none)_ | Health check; sent after Max bind and after Python restart. |
| Python -> Max | `/status/pong` | `int` (`1`) | Health response. |
| Max -> Python | `/control/reload` | _(none)_ | Reload CSV without restart. |

### Optional debug addresses

| Direction | OSC address | Payload | Purpose |
|---|---|---|---|
| Python -> Max | `/debug/probability` | `float` | Probability of selected transition. |
| Python -> Max | `/debug/candidates` | `int` | Number of available next states. |
| Python -> Max | `/debug/input_echo` | `string` | Echo received chord for traceability. |
| Python -> Max | `/debug/fallback_used` | `int` | `1` if fallback logic was triggered, else `0`. |

Debug messages are emitted only when Python debug mode is enabled (default off).

### Contract rules

- Chord symbols are UTF-8 strings sent as OSC string arguments.
- OSC addresses are stable and must not be renamed without updating both sides.
- Error messages should be human-readable.
- Debug messages must not be required for core operation.
- Protocol version `v1` is recorded in Python constants and Max patch comments.
- Duplicate sends from Max are acceptable; Python treats each `/chord/input` independently.
- If Max does not receive `/chord/output` within 500 ms, it shows a timeout error and allows the user to retry.

## Max OSC stack (default)

Raw `udpsend` / `udpreceive` carry UDP bytes, not OSC messages. v1 uses the **CNMAT OSC externals**:

| Role | Objects |
|---|---|
| Pack outgoing OSC | `o.pack`, `o.prepend` |
| Send | `udpsend` |
| Receive | `udpreceive` |
| Route incoming OSC | `o.route`, `o.unpatch` |

Canonical outgoing pattern for chord input:

```text
[chord symbol] -> prepend s -> o.pack /chord/input -> udpsend 127.0.0.1 9000
```

Incoming routing handles at minimum: `/chord/output`, `/status/ready`, `/status/pong`, `/error`, and optional `/debug/*` addresses.

If CNMAT is unavailable in the target environment, stop and document the substitute OSC pack/route library before continuing; do not send raw string payloads over UDP and assume Python will parse them.

## Configuration (default)

Python reads configuration from **CLI flags with environment-variable overrides**:

| Setting | CLI flag | Env var | Default |
|---|---|---|---|
| CSV path | `--csv` | `MARKOV_CSV` | `data/markov_openbook.csv` |
| Bind host | `--host` | `MARKOV_HOST` | `127.0.0.1` |
| Listen port | `--port` | `MARKOV_PORT` | `9000` |
| Max reply host | `--max-host` | `MARKOV_MAX_HOST` | `127.0.0.1` |
| Max reply port | `--max-port` | `MARKOV_MAX_PORT` | `9001` |
| Fallback policy | `--fallback` | `MARKOV_FALLBACK` | `echo_input` |
| Debug mode | `--debug` | `MARKOV_DEBUG` | off |
| Random seed | `--seed` | `MARKOV_SEED` | unset (non-deterministic); use `42` in tests |

Example:

```bash
MARKOV_SEED=42 python -m src.main --csv data/markov_openbook.csv
```

## Data handling plan

### CSV validation

The Python service validates the CSV at startup **before** opening the OSC service port.

Validation checks:

1. File exists and is readable.
2. Header contains at least these required fields: `chord_from`, `chord_to`, `count`, `probability`.
3. `count` parses as a non-negative integer.
4. `probability` parses as a non-negative float.
5. No empty or whitespace-only `chord_from` or `chord_to` values.
6. Duplicate `(chord_from, chord_to)` rows are merged: counts summed, probabilities recomputed from merged counts, and merges logged in `stats`.
7. Probability sums per `chord_from` are checked; renormalize if sum drifts more than `0.01` from `1.0` (tolerate minor float rounding).
8. After grouping, at least one source chord exists and the global fallback pool (top target chords by total count) is non-empty.

### In-memory model

Target data shape in Python:

```python
transitions = {
    "G:7": [
        {"to": "C:maj", "count": 529, "prob": 0.462},
        {"to": "C:maj7", "count": 241, "prob": 0.2105},
    ]
}
```

Recommended derived structures:

- `transitions_by_source`: grouped raw rows.
- `weighted_choices_by_source`: tuple lists ready for sampling.
- `global_fallback_pool`: list of globally common target chords (default fallback source).
- `stats`: source chord count, row count, normalization fixes, duplicates merged.

### Sampling behavior

For each incoming source chord:

1. Strip leading/trailing whitespace from the input string.
2. Reject empty strings: emit `/error` with message `empty chord input` and do not emit `/chord/output`.
3. Look up all candidate rows for that `chord_from`.
4. Normalize probabilities if needed.
5. Sample one `chord_to` with weighted randomness (`random.choices` or equivalent).
6. Return the selected chord on `/chord/output`.
7. When debug mode is enabled, emit debug addresses listed above.

Unknown chord fallback policies (configurable via `--fallback` / `MARKOV_FALLBACK`):

| Policy | Behavior |
|---|---|
| `echo_input` **(v1 default)** | Emit `/error`, then return the input chord unchanged on `/chord/output`. |
| `global_top` | Emit `/error`, then return the most frequent global target chord. |
| `random_source` | Emit `/error`, then sample a random known source and one of its outputs. |
| `error_only` | Emit `/error` only; no `/chord/output`. |

## Max device requirements

### Functional requirements

- Manual chord input field for quick testing.
- Send trigger button.
- Host and port UI controls (defaults: `127.0.0.1`, Python port `9000`, Max receive port `9001`).
- Connection/status indicator driven by ping/pong or `/status/ready`.
- Output chord display.
- Error display or console routing, including reply timeout messages.
- Optional toggle to show debug messages.
- Optional symbol outlet for downstream Max logic (MIDI mapping deferred).

### Max patch modules

Suggested internal patch structure:

1. **Input module** — text entry or symbol input.
2. **OSC sender module** — CNMAT pack + `udpsend` for `/chord/input`, `/control/ping`, `/control/reload`.
3. **OSC receiver module** — `udpreceive` + CNMAT route for replies and status.
4. **UI/state module** — ready state, last sent/received chord, last error, reply timeout timer (500 ms).
5. **Output module** — emits the generated chord as a symbol.

### Max validation checkpoints

- Can a fixed OSC test message be sent to Python?
- Does Max receive a fixed reply from Python?
- Do `/status/pong`, `/status/ready`, and `/error` route correctly?
- Does a 500 ms timeout appear when Python is stopped?
- Do host and port UI changes affect transport correctly?
- Can the patch recover after Python is restarted via `/control/ping`?

## Python service requirements

### Functional requirements

- Configurable CSV path, host, and ports (CLI + env vars; see Configuration).
- Startup CSV load with validation before serving.
- OSC listener for incoming chord and control messages.
- Weighted sampling engine with optional `MARKOV_SEED`.
- OSC client reply path using `python-osc`.
- Structured logging to console.
- Reload and ping endpoints.

### Concurrency and reload safety

- `python-osc` dispatches handlers on a background thread.
- CSV reload swaps the in-memory transition table atomically (build new table, then replace under a lock).
- On reload failure, keep the previous valid table and emit `/error`; do not enter a broken state.
- Keep handler work short; do not block the OSC thread on file I/O beyond a normal reload.

### Suggested Python modules

```text
python/
  requirements.txt
  src/
    config.py          # CLI + env parsing, constants (protocol v1, OSC addresses)
    csv_loader.py
    markov_engine.py
    osc_service.py     # combined OSC server + client dispatch
    main.py
  tests/
    test_csv_loader.py
    test_markov_engine.py
    test_osc_flow.py
  scripts/
    osc_smoke_test.py  # Phase 1.5: send /chord/input, assert /chord/output
```

### Python validation checkpoints

- Does CSV loading fail clearly on schema issues?
- Are duplicate transitions merged consistently with logged counts?
- Do grouped probabilities normalize correctly?
- Does `/chord/input` produce `/chord/output` for a known chord?
- Does an unknown chord trigger configured fallback behavior?
- Does startup emit `/status/ready` only after successful load?
- Does `/control/reload` rebuild state safely under concurrent requests?
- Does `/control/ping` always produce `/status/pong`?

## Recommended build order

This sequence leaves room for explicit verification after each stage.

### Phase 1: Define interfaces

Deliverables:

- OSC contract (this document).
- Port and configuration defaults.
- CSV schema note and default file choice.
- Fallback policy: `echo_input`.

Validation gate:

- Agent confirms Max and Python specs reference identical OSC addresses and payload types.

### Phase 1.5: Python OSC smoke test (no Max)

Deliverables:

- `scripts/osc_smoke_test.py` that sends `/chord/input "G:7"` and listens for a reply on port `9001`.

Validation gate:

- Smoke script passes against the Phase 2 hardcoded Python service before Max work begins.

### Phase 2: Build Python skeleton

Deliverables:

- Config loader (CLI + env).
- Minimal OSC service with hardcoded reply path.

Validation gate:

- `/chord/input "G:7"` returns fixed `"C:maj"` on `/chord/output`.
- Startup sends `/status/ready 1`.
- `/control/ping` returns `/status/pong 1`.
- Errors are visible in logs.

### Phase 3: Build Max transport patch

Deliverables:

- Standalone `.maxpat` with CNMAT OSC wiring.
- Manual input UI, send trigger, status/error UI, 500 ms timeout.

Validation gate:

- Max can trigger Python and display the fixed reply.
- Max reaches ready state via ping/pong after bind.
- Restarting Python and re-pinging restores normal flow without patch changes.

### Phase 4: Implement CSV loader

Deliverables:

- CSV parser, schema validator, duplicate merge, group-by-source map, probability normalization.

Validation gate:

- Unit tests pass with good and bad CSV samples.
- Loader reports row counts, source chord counts, merges, and normalization actions.

### Phase 5: Implement Markov engine

Deliverables:

- Weighted sampler, unknown-chord fallback, optional debug metadata, `MARKOV_SEED` support.

Validation gate:

- Repeated calls for a known chord roughly match expected distribution over many samples (use `MARKOV_SEED=42` in tests).
- Unknown, empty, and whitespace-only inputs behave per policy.

### Phase 6: Integrate full path

Deliverables:

- End-to-end Max -> Python -> Max flow with real sampling.

Validation gate:

- Manual tests pass for known chords, unknown chords, and malformed inputs.
- Debug messages remain optional and non-blocking.

### Phase 7: Harden for use

Deliverables:

- Reload command, ping/pong health check, improved logging, basic usage notes in `max/README.md`.

Validation gate:

- Python reloads data without crashing; failed reload preserves prior table.
- Max accurately reflects ready/not-ready state.
- Common failure cases produce useful messages.

## Acceptance criteria

| Area | Acceptance criterion |
|---|---|
| Transport | Max sends `/chord/input` and receives `/chord/output` over OSC/UDP on localhost. |
| Readiness | Max reaches ready via ping/pong; recovers after Python restart. |
| Timeouts | Max shows an error if no reply within 500 ms. |
| Data load | Python loads and validates CSV before serving; default file is `markov_openbook.csv`. |
| Markov behavior | Known chords produce weighted random outputs from valid `chord_to` candidates. |
| Fallbacks | Unknown chords emit `/error` and apply `echo_input` fallback by default. |
| UX | Max exposes manual testing controls, status, and output display. |
| Security | Python binds to `127.0.0.1` only in v1. |
| Observability | Both sides provide enough logging or UI to debug routing problems. |

## Test matrix

Implement tests progressively and stop after each block to verify results.

### Unit tests (automated)

- CSV header validation.
- Numeric parsing validation.
- Duplicate row merge.
- Probability normalization.
- Weighted sampling returns only legal targets.
- Unknown, empty, and whitespace-only chord fallback behavior.
- Deterministic output with `MARKOV_SEED=42`.

### Integration tests (automated, Python-side)

- Python receives OSC message and returns correct address and payload type.
- `/control/ping` returns `/status/pong 1`.
- Reload command updates active transitions.
- Reload failure preserves previous table.

### Integration tests (manual, Max-side)

- Max receives and routes `/chord/output`.
- Max receives and routes `/error`.
- Max timeout fires when Python is stopped.
- Max recovers after Python restart via ping.

### Manual tests

| Test | Input | Expected result |
|---|---|---|
| Known chord | `G:7` | Returns one of the legal transitions from CSV. |
| Unknown chord | `X:???` | Emits `/error` and echoes input (`echo_input`). |
| Empty string | `""` | Emits `/error`; no `/chord/output`. |
| Whitespace only | `"   "` | Same as empty string. |
| Python restart | send after restart | Ping restores ready; normal flow resumes. |
| Reply timeout | Python stopped | Max shows timeout after 500 ms. |
| Bad CSV at startup | malformed file | Python refuses service start. |
| Bad CSV on reload | malformed file | `/error`; previous table remains active. |

## Error handling policy

| Condition | Behavior |
|---|---|
| Invalid CSV at startup | Do not open OSC server; exit with clear log message. |
| Unknown chord | Emit `/error`; apply configured fallback (default `echo_input`). |
| Empty or whitespace-only chord | Emit `/error` (`empty chord input`); no output. |
| Malformed OSC payload | Emit `/error`; ignore message. |
| Port bind failure | Fail loudly with actionable log output. |
| Reload failure | Keep previous valid transition table; emit `/error`. |
| Lost reply (Max-side) | Show timeout error after 500 ms; user may retry. |

## Logging and observability

### Python logs

Log at least:

- Service start and effective config (host, ports, CSV path, fallback policy).
- CSV load summary (rows, sources, merges, normalizations).
- Ready state.
- Incoming chords and selected outputs when debug mode is on.
- Errors, fallback usage, reload results.

### Max observability

- Visible ready indicator (from ping/pong or `/status/ready`).
- Last input chord.
- Last output chord.
- Last error string (including timeouts).
- Optional debug message display toggle.

## Suggested repository layout

```text
project-root/
  PLAN.md                         # canonical spec (v1 + v2 JazzNet plan)
  markov_openbook.csv             # source corpus (copy or symlink into data/)
  chord_progressions_transitions.csv
  max/
    chord_generator_device.maxpat    # v2: adds model switcher UI
    markov_osc.js                 # v2: /control/model handler
    README.md
  python/
    requirements.txt              # v2: adds torch
    src/
      config.py
      csv_loader.py
      markov_engine.py            # v2: may move to engines/markov_engine.py
      osc_service.py
      main.py
      engines/                    # v2
        base.py
        jazznet_models.py
        jazznet_vocab.py
        jazznet_inference.py
        rnn_engine.py
        lstm_engine.py
        registry.py
      chord_simplifier.py         # v2
    tests/
      test_csv_loader.py
      test_markov_engine.py
      test_osc_flow.py
      test_jazznet_vocab.py       # v2
      test_jazznet_inference.py   # v2
      test_engine_registry.py     # v2
    scripts/
      osc_smoke_test.py
      fetch_jazznet_assets.py     # v2
  data/
    markov_openbook.csv           # default Markov runtime path
    chord_progressions_transitions.csv
    jazznet/                      # v2 (checkpoints via fetch script)
      chords.json
      checkpoints/
        rnn/baselineRNN-epoch35.pt
        lstm/ChordLSTM-epoch35.pt
      metadata.json
  docs/
    osc_contract.md               # v2: mirror new /control/model addresses
```

## Coding agent brief

> Build a local Max + Python system where a standalone Max/MSP patch sends one chord symbol to Python over OSC/UDP and Python returns one next chord sampled from a first-order Markov chain loaded from `data/markov_openbook.csv`. Keep chord strings opaque in v1. Use CNMAT OSC objects in Max and `python-osc` in Python. Define the OSC contract first (this document is canonical), then implement Python transport with a hardcoded reply and an OSC smoke script, then Max transport with ping/pong readiness and a 500 ms reply timeout, then CSV loading with duplicate merge, then weighted sampling with `echo_input` fallback, then reload and health checks. After each phase, stop and validate before proceeding. Do not assume a step works without a runnable verification. Bind Python to `127.0.0.1` only. Prefer simple localhost defaults, visible logs, and stable OSC addresses.

## Implementation notes for the agent

- Keep configuration in CLI flags and env vars; do not hardcode ports or paths in multiple places.
- Mirror OSC address constants in Python `config.py` and Max patch comments; keep them identical to this document.
- Avoid mixing chord-generation logic with transport logic.
- Use `MARKOV_SEED=42` for deterministic unit and distribution tests.
- Make fallback behavior explicit and configurable.
- Preserve the last valid transition table on reload failure.
- Leave extension points for later features: history-aware generation, Max for Live packaging, confidence display, or note-level rendering.

## Future extensions

Possible later improvements (beyond v2):

- Higher-order chains based on chord history (stateful RNN session mode).
- Beat-synchronous triggering from Max transport.
- Max for Live device wrapper.
- Symbol-to-voicing generation inside Max.
- Confidence/probability visualization.
- Corpus switching by style or song section.
- Remote host support with explicit non-localhost bind.
- Full progression generation endpoint (multi-chord sequences from JazzNet).

## Definition of done (v1)

The project is done for v1 when the standalone Max patch can send a chord like `G:7`, Python can read `markov_openbook.csv`, choose a valid next chord such as `C:maj` or `C:maj7` according to weighted probabilities, and Max can receive and display that response reliably through OSC/UDP on localhost—with ping/pong readiness, 500 ms timeout handling, and `echo_input` fallback for unknown chords.

---

# v2 — JazzNet RNN / LSTM integration

## Objective (v2)

Extend the existing Max + Python chord service so the user can choose **three generation backends** from the Max patch:

| Mode | Source | Behavior |
|---|---|---|
| `markov` | `data/markov_openbook.csv` | Existing first-order weighted transition lookup (v1). |
| `rnn` | JazzNet baseline RNN checkpoint | Single-step next-chord prediction via trained RNN. |
| `lstm` | JazzNet ChordLSTM checkpoint | Single-step next-chord prediction via trained LSTM. |

Trained weights come from [JazzNet](https://github.com/scalzadonna/JazzNet) branch **`train`**:

- `models/rnn/baselineRNN-epoch35.pt`
- `models/lstm/ChordLSTM-epoch35.pt`
- Vocabulary derived from `data/processed/chords.json` (933 sequences, 115 simplified chord types + special tokens)

Each `/chord/input` request remains **one input chord → one output chord**, matching the Markov UX. The neural models run **stateless single-step** inference: context is always `[<BOS>, input_chord]`, not an accumulating session history.

## Scope (v2)

### In scope

- Copy JazzNet checkpoints and vocab data into this repo under `data/jazznet/`.
- Port minimal JazzNet inference code (model classes, vocab encoding, next-token sampling).
- Refactor Python sampling behind a shared engine interface; select backend at runtime.
- Max patch model switcher (`umenu` or equivalent) sending OSC model-change messages.
- Startup validation: Markov CSV always loaded; RNN/LSTM loaded lazily or eagerly with clear errors if assets missing.
- Reuse existing fallback policies for unknown / unmappable input chords.
- Tests for vocab mapping, engine dispatch, and at least one checkpoint smoke test.

### Out of scope for v2

- Retraining or fine-tuning JazzNet models.
- Full sequence generation (multi-chord progressions) from Max.
- Stateful RNN hidden-state carry-over across multiple `/chord/input` calls.
- GPU requirement (CPU inference is sufficient for local Max use).
- Changing v1 OSC addresses or breaking Markov-only workflows.

## JazzNet assets to vendor

Copy from `https://github.com/scalzadonna/JazzNet` branch `train`:

```text
data/jazznet/
  chords.json                          # processed corpus → builds vocab (118 tokens incl. pad/BOS/EOS)
  checkpoints/
    rnn/baselineRNN-epoch35.pt         # ~934 KB
    lstm/ChordLSTM-epoch35.pt          # ~2.9 MB
  metadata.json                        # hyperparams + source commit (generated by fetch script)
```

Provide a one-time fetch script (not committed binary blobs in git history if LFS is preferred — document both options):

```bash
python/scripts/fetch_jazznet_assets.py --branch train --epoch 35
```

**Note:** Checkpoints are PyTorch `state_dict` files; they are loaded with architecture hyperparameters fixed to the JazzNet training run:

| Hyperparameter | Value |
|---|---|
| `embedding_dim` | 48 |
| `hidden_dim` | 128 |
| `n_layers` | 2 |
| `dropout` | 0.3 |
| `vocab_size` | 118 |
| `padding_idx` | 0 |

Token layout (from `chords.json` + `encode_chords`):

| Index | Token |
|---|---|
| 0 | `pad` |
| 1 | `<BOS>` |
| 2 | `<EOS>` |
| 3–117 | simplified chord symbols (e.g. `G:7` → 111, `C:maj` → 46) |

## Chord label mapping (Markov ↔ JazzNet)

Markov CSV and JazzNet share a similar string format (`G:7`, `C:maj7`), but JazzNet uses a **115-chord simplified vocabulary** built with `ChordSimplifier`.

Input normalization pipeline for RNN/LSTM:

1. Strip whitespace from OSC input.
2. If chord is in JazzNet vocab → use directly.
3. Else run `ChordSimplifier.simplify_chord()` (port from JazzNet `functions/ChordSimplifier.py`).
4. If still not in vocab → apply configured fallback (`echo_input` default), emit `/error`.

This keeps Max chord entry unchanged while allowing openbook-style labels to map into the neural vocab when possible.

## Proposed Python architecture (v2)

Introduce a small engine abstraction so transport code stays unchanged:

```python
# python/src/engines/base.py
@dataclass(frozen=True)
class SampleResult:
    output: str | None
    probability: float | None   # Markov: transition prob; RNN/LSTM: sampled token prob
    candidates: int             # Markov: row count; RNN/LSTM: vocab size (or 0)
    fallback_used: bool
    error: str | None = None

class ChordEngine(Protocol):
    name: str  # "markov" | "rnn" | "lstm"
    def sample(self, raw_input: str) -> SampleResult: ...
```

Suggested modules:

```text
python/
  src/
    engines/
      __init__.py
      base.py              # SampleResult + ChordEngine protocol
      markov_engine.py       # move from markov_engine.py (unchanged logic)
      jazznet_models.py      # ChordLSTM, baselineRNN (from JazzNet Models.ipynb)
      jazznet_vocab.py       # load chords.json, build chord_to_idx / idx_to_chord
      jazznet_inference.py   # predict_next_chord(model, context, multinomial sample)
      rnn_engine.py          # wraps baselineRNN + vocab + simplifier
      lstm_engine.py         # wraps ChordLSTM + vocab + simplifier
      registry.py            # EngineRegistry: get/set active engine, lazy torch load
    chord_simplifier.py      # minimal port of JazzNet ChordSimplifier
    osc_service.py           # dispatch sample() to active engine
    config.py                # add model + jazznet paths
  scripts/
    fetch_jazznet_assets.py
  tests/
    test_jazznet_vocab.py
    test_jazznet_inference.py
    test_engine_registry.py
```

### Single-step inference (Markov-analog)

For input chord `X`, mirror JazzNet training (predict next token given prefix):

```text
context indices = [<BOS>, idx(X)]
logits = model(context)[-1]
probs  = softmax(logits)
next_idx = multinomial(probs)   # same as JazzNet generate_sequence
output = idx_to_chord[next_idx]  # reject pad/BOS/EOS → resample or fallback
```

- **LSTM:** forward with `lengths=[len(context)]` and sequence packing (as in JazzNet).
- **RNN:** forward without packing (as in JazzNet `rnn=True` path).
- **Randomness:** use `MARKOV_SEED` / `--seed` for torch + python RNG when set.

### Engine loading strategy

| Engine | When loaded | Failure mode |
|---|---|---|
| `markov` | At startup (required) | Service refuses to start (existing v1 behavior). |
| `rnn`, `lstm` | Lazy on first select or at startup if `--model` set | `/error` on select or first sample; Markov remains usable. |

Lazy loading avoids ~3 s torch import + model init when user only wants Markov.

## OSC contract extension (v2)

Keep all v1 addresses unchanged. Add:

| Direction | OSC address | Payload | Purpose |
|---|---|---|---|
| Max → Python | `/control/model` | `string` | Set backend: `markov`, `rnn`, or `lstm`. |
| Python → Max | `/status/model` | `string` | Confirm active backend after change or on ping/ready. |
| Python → Max | `/debug/model` | `string` | Active backend (only when debug mode on). |

Rules:

- Invalid model name → `/error`; keep previous backend.
- `/control/reload` reloads Markov CSV; optionally reloads neural checkpoints if present (same paths).
- `/status/ready` and `/status/pong` should be followed by `/status/model` so Max can sync UI after reconnect.
- Protocol version string becomes **`v2`** in logs/constants; v1 clients that ignore new messages continue to work with Markov default.

### Example trace (LSTM mode)

```text
Max  -> Python:  /control/model  s  "lstm"
Python -> Max:   /status/model    s  "lstm"
Max  -> Python:  /chord/input     s  "G:7"
Python -> Max:   /chord/output    s  "C:maj7"
Python -> Max:   /debug/model     s  "lstm"
Python -> Max:   /debug/probability f 0.083
```

## Configuration (v2 additions)

| Setting | CLI flag | Env var | Default |
|---|---|---|---|
| Active model | `--model` | `CHORD_MODEL` | `markov` |
| JazzNet data dir | `--jazznet-dir` | `JAZZNET_DIR` | `data/jazznet` |
| Checkpoint epoch | `--jazznet-epoch` | `JAZZNET_EPOCH` | `35` |

Existing Markov settings (`--csv`, `--fallback`, `--seed`, ports, etc.) unchanged.

Example:

```bash
CHORD_MODEL=lstm python -m src.main
# or switch at runtime from Max via /control/model
```

## Max device changes (v2)

Update `max/chord_generator_device.maxpat` and `max/markov_osc.js`:

1. **Model switcher UI** — `umenu` items: `markov`, `rnn`, `lstm` (default `markov`).
2. On selection change → send `/control/model <name>` via existing OSC client.
3. Route incoming `/status/model` → update menu display / comment label (avoid feedback loop: only update UI if different from local selection).
4. Add `model` handler in `markov_osc.js`:

```javascript
Max.addHandler("model", (name) => sendOsc("/control/model", String(name)));
```

5. Optional: rename patch title comment to “Chord Generator v2” (file name can stay for compatibility).

No change to chord input, send button, timeout, or output routing.

## Dependencies (v2)

Add to `python/requirements.txt`:

```text
torch>=2.0.0
```

CPU wheel is fine. Document install note in README (first LSTM/RNN load may take a few seconds).

## Recommended build order (v2)

### Phase 8: Vendor JazzNet assets

Deliverables:

- `fetch_jazznet_assets.py` downloads checkpoints + `chords.json` from branch `train`.
- `data/jazznet/` layout populated locally.
- `metadata.json` records epoch, branch, and hyperparameters.

Validation gate:

- Files exist and sizes match (~934 KB RNN, ~2.9 MB LSTM).
- `chords.json` loads; vocab size = 118.

### Phase 9: JazzNet inference module

Deliverables:

- `jazznet_models.py`, `jazznet_vocab.py`, `jazznet_inference.py`, `chord_simplifier.py`.
- Unit tests: vocab indices for `G:7`, simplifier mapping, forward pass shape.

Validation gate:

- Load both checkpoints; `predict_next("G:7")` returns a legal chord string (not BOS/EOS/pad).

### Phase 10: Engine registry + OSC model switching

Deliverables:

- `EngineRegistry` with Markov + lazy RNN/LSTM.
- `/control/model`, `/status/model`, config flags.
- Refactor `osc_service.py` to call `registry.sample()`.

Validation gate:

- OSC smoke test: set model to `lstm`, send `G:7`, receive output.
- Switch back to `markov`; behavior matches v1 tests.
- Missing checkpoint → clear `/error`, Markov still works.

### Phase 11: Max switcher UI

Deliverables:

- `umenu` + wiring in patch and JS bridge.

Validation gate:

- Selecting each model in Max changes Python backend (visible in logs + `/status/model`).
- Send/ping/reload/timeout still work.

## Acceptance criteria (v2)

| Area | Acceptance criterion |
|---|---|
| Backward compat | Default startup uses Markov; v1 tests still pass unchanged. |
| Assets | Checkpoints and vocab live under `data/jazznet/`; fetch script documented. |
| RNN mode | `/control/model rnn` + `/chord/input G:7` → legal next chord from JazzNet vocab. |
| LSTM mode | Same for `lstm`. |
| Max UI | Model switcher sends OSC and reflects `/status/model`. |
| Unknown chords | Unmapped input triggers fallback + `/error` (same policies as v1). |
| Performance | First neural request completes within ~500 ms on CPU after model is loaded (Max timeout may need bump to 1500 ms for **first** load only — document or preload on model select). |

## Test matrix (v2 additions)

### Unit tests

- Vocab build from `chords.json` matches expected BOS/EOS indices.
- `ChordSimplifier` maps representative openbook labels into vocab.
- Engine registry rejects invalid model names.
- Deterministic sampling with fixed seed (mock or real checkpoint).

### Integration tests

- `/control/model lstm` then `/chord/input G:7` → `/chord/output`.
- Switch `markov` → output distribution differs from LSTM (sanity, not exact values).
- `/status/model` emitted on ping when non-markov active.

### Manual tests

| Test | Steps | Expected |
|---|---|---|
| Model switch | Select `lstm` in Max, send `G:7` | Output chord displayed; Python log shows `lstm`. |
| Markov regression | Select `markov`, send `G:7` | Same behavior as v1. |
| Missing torch | Uninstall torch, select `rnn` | `/error` with actionable message. |
| Unknown chord | Send `X:???` in LSTM mode | `/error` + echo fallback. |

## Open questions for review

1. **First-load timeout:** Neural model cold start may exceed Max’s 500 ms reply timeout. Options: (A) preload on `/control/model`, (B) bump timeout to 1500 ms globally, (C) send immediate `/status/model` ack and async `/chord/output` (more complex). **Recommendation:** preload on model select + keep 500 ms for `/chord/input` after load.
2. **Git LFS for checkpoints:** ~4 MB total — acceptable in-repo, or fetch-on-demand only? **Recommendation:** fetch script + `.gitignore` the `.pt` files; document one-time setup.

## Definition of done (v2)

The v2 integration is complete when the Max patch exposes a three-way model switcher; Python serves Markov, JazzNet RNN, and JazzNet LSTM backends over the existing OSC transport; checkpoints are vendored via documented fetch script; and a user can send `G:7` in any mode and receive a valid next-chord reply with the same UX as v1 Markov sampling.

---

# v3 — Stateful session mode (Phase 12)

## Objective (v3)

Extend RNN/LSTM backends so chord steps **accumulate hidden state** across `/chord/input` calls. Markov stays first-order (stateless). Same Max UX: one chord in, one chord out.

## Scope (v3)

### In scope

- `NeuralSessionState` with RNN/LSTM hidden carry-over
- Auto-feed model output token into session after each sample
- Session **auto** default: enabled for `rnn`/`lstm`, disabled for `markov`
- Auto-reset after `SESSION_MAX_STEPS` (default 64) user steps
- OSC: `/control/session`, `/status/session`, `/debug/session_history`
- Max patch session menu + reset button + step display
- Tests for session step increment, reset, model switch, max-steps auto-reset

### Out of scope for v3

- Higher-order Markov chains (Phase 13)
- Full multi-chord progression endpoint without per-step user input

## Session semantics

| Setting | Behavior |
|---|---|
| `auto` (default) | Session on for RNN/LSTM; off for Markov |
| `stateless` | Single-step `[BOS, input]` for all models |
| `session` | Force session for RNN/LSTM |
| `reset` | Clear hidden state and step counter |

Each user `/chord/input`:

1. Forward user chord through model (with carried hidden after step 1)
2. Sample and return next chord
3. Auto-feed sampled chord into hidden state (default on)

Reset triggers: explicit `/control/session reset`, model switch, session mode → `stateless`, max steps reached.

## OSC additions (v3)

| Direction | Address | Payload |
|---|---|---|
| Max → Python | `/control/session` | `auto` \| `stateless` \| `session` \| `reset` |
| Python → Max | `/status/session` | string mode, int step |
| Python → Max | `/debug/session_history` | string (debug only) |

## Phase 12 deliverables

- `python/src/engines/neural_session.py`, `neural_sampler.py`
- `predict_step()` / `forward_token()` in `jazznet_inference.py`
- Registry + OSC wiring; protocol bump to **v3**
- Max `session` umenu, **reset session** button, step display
- `test_neural_session.py` + OSC integration tests

## Validation gate

- 81+ pytest tests pass
- RNN/LSTM with `auto`: step increments across sends; reset clears step
- Markov unchanged (stateless)
- v2 single-step behavior available via `--session-mode stateless`

## Definition of done (v3)

The v3 session integration is complete when RNN/LSTM backends remember chord context across Max sends (with auto-feed and auto-reset), Markov behavior is unchanged, and the Max patch exposes session controls with step feedback over OSC.
