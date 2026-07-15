# OSC contract mirror — canonical spec is ../PLAN.md (protocol v3)

See [PLAN.md](../PLAN.md) sections **OSC contract** and **Max OSC stack**.  
Colleague testing: [TESTING.md](TESTING.md).

Both Max devices — `chord_generator_device` and `chord_sequencer_device` — speak
this **same** v3 contract; the sequencer adds **no new OSC addresses** (its clock
and harmonic-rhythm templates are entirely Max-side). Verify this doc against the
service with `python3 python/scripts/check_osc_contract.py`.

Required addresses:

| Direction | Address | Payload |
|---|---|---|
| Max → Python | `/chord/input` | string |
| Python → Max | `/chord/output` | string |
| Python → Max | `/status/ready` | int `1` |
| Python → Max | `/error` | string |
| Max → Python | `/control/ping` | none |
| Python → Max | `/status/pong` | int `1` |
| Max → Python | `/control/reload` | none |
| Max → Python | `/control/model` | string (`markov`, `rnn`, `lstm`) |
| Python → Max | `/status/model` | string |
| Max → Python | `/control/session` | string (`auto`, `stateless`, `session`, `reset`) |
| Python → Max | `/status/session` | string mode, int step |
| Max → Python | `/control/spice` | float `0.0`–`1.0` (adventurousness; `0.5` = neutral, higher = wilder) |

Debug (Python → Max, only when the service runs with `--debug`):

| Address | Payload |
|---|---|
| `/debug/input_echo` | string — the input chord, echoed for traceability |
| `/debug/candidates` | the candidate next-states considered for the reply |
| `/debug/probability` | float — probability of the chosen chord |
| `/debug/fallback_used` | int `1`/`0` — whether the echo-input fallback fired |
| `/debug/model` | string — active model name at sample time |
| `/debug/session_history` | string — comma-separated token trace |

Default ports: Python `9000`, Max `9001`, host `127.0.0.1`.

Session defaults (`SESSION_MODE=auto`): RNN/LSTM use session mode; Markov is always stateless. Session auto-resets after `SESSION_MAX_STEPS` (default 64) user chord steps.

Spice (`/control/spice`): a live sampling temperature applied to Markov **and** the neural engines. `0.5` is neutral (temperature `1.0`); higher values flatten the distribution toward rarer/surprising chords, lower values sharpen toward safe/common ones (mapped `temperature = 3 ** (value − 0.5)`).

## Internal Max messages (not part of the OSC contract)

`markov_osc.js` also exchanges plain Max messages with its patch. These are
**internal to the device**, never sent over OSC to Python, and are listed only
for completeness:

- **Patch → bridge (shared by both devices):** `ping`, `reload`, `send`, `chord`, `model`, `spice`, `session`, `reset_session`, `notein`.
- **Patch → bridge (sequencer only):** `play`, `beat`, `rhythm`, `template`, `length`, `seed`, `register`, `voiceleading`, `triadsonly`, `colormajor`, `colorminor`, `color7th`, `panic`, `testparse`.
- **Bridge → patch (routed outlets):** `status`, `output`, `error`, `chord`, `notes`, `stop`, `playoff`, `rhythmname`, `model`, `session`.
