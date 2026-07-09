# OSC contract mirror — canonical spec is ../PLAN.md (protocol v3)

See [PLAN.md](../PLAN.md) sections **OSC contract** and **Max OSC stack**.  
Colleague testing: [TESTING.md](TESTING.md).

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

Debug (when `--debug`):

| Direction | Address | Payload |
|---|---|---|
| Python → Max | `/debug/session_history` | string (comma-separated token trace) |

Default ports: Python `9000`, Max `9001`, host `127.0.0.1`.

Session defaults (`SESSION_MODE=auto`): RNN/LSTM use session mode; Markov is always stateless. Session auto-resets after `SESSION_MAX_STEPS` (default 64) user chord steps.

Spice (`/control/spice`): a live sampling temperature applied to Markov **and** the neural engines. `0.5` is neutral (temperature `1.0`); higher values flatten the distribution toward rarer/surprising chords, lower values sharpen toward safe/common ones (mapped `temperature = 3 ** (value − 0.5)`).
