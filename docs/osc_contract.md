# OSC contract mirror — canonical spec is ../PLAN.md (protocol v1)

See [PLAN.md](../PLAN.md) sections **OSC contract** and **Max OSC stack**.

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

Default ports: Python `9000`, Max `9001`, host `127.0.0.1`.

## Node → Max messages (in-patch, not OSC)

The OSC contract above (Max ↔ Python) is **unchanged**. `markov_osc.js`
additionally emits these messages to the patch's `route status output error
chord notes stop` object. `output` stays backward-compatible; `chord`/`notes`/
`stop` drive the display and the major/minor-triad MIDI branch.

| Message | Payload | Purpose |
|---|---|---|
| `status` | word | `ready` / `waiting` |
| `output` | symbol | raw Markov reply (unchanged) |
| `error` | code [detail] | passthrough or parser error |
| `chord` | symbol | normalized returned symbol for display |
| `notes` | midi ints | voiced major/minor triad |
| `stop` | — | silence held notes (N.C. / panic) |
