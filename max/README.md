# Chord Markov Max Device (protocol v1)

Standalone Max/MSP patch that sends chord symbols to the Python Markov OSC service and displays the sampled reply.

Uses **Node for Max** (`node.script` + `node-osc`) — **CNMAT externals are not required**.

## Requirements

- Max 8+ with Node for Max (included in standard Max 8 installs)
- Python service running locally (see below)
- One-time npm install from inside the patch (see Quick start)

## Quick start

### 1. Start Python

From the repo root:

```bash
cd python
python3 -m pip install -r requirements.txt
python3 -m src.main
```

### 2. Open the patch

Open `chord_markov_device.maxpat` in Max.

### 3. Install npm dependencies (first time only)

Click **npm install** in the patch. Wait until the Max console shows npm finished (may take ~30 seconds).

Alternatively, from a terminal:

```bash
cd max
npm install
```

### 4. Ping and send

1. Click **ping** — status should show `ready` when Python replies.
2. Click the **G:7 message box** to edit the chord (do not use textedit — it sends a `text` prefix that breaks routing).
3. Click **send** — the sampled next chord appears in **output**.
4. After updating `markov_osc.js`, click **restart js** before testing again.

Click **reload** to reload the CSV without restarting Python.

## Default ports

| Role | Host | Port |
|---|---|---|
| Python listen | `127.0.0.1` | `9000` |
| Max listen | `127.0.0.1` | `9001` |

Ports are set in `markov_osc.js`. Change them there if you use non-default Python ports.

## Controls

| UI | Action |
|---|---|
| **npm install** | Runs `script npm install` to fetch `node-osc` (first time only) |
| **ping** | Sends `/control/ping` |
| **send** | Sends `/chord/input` with the text field value |
| **reload** | Sends `/control/reload` |
| status | Shows `ready` or `waiting` |
| output | Last `/chord/output` chord symbol |
| error | Last `/error` or `reply timeout` after 500 ms |

## Files in this folder

| File | Purpose |
|---|---|
| `chord_markov_device.maxpat` | Max UI wired to the Node bridge |
| `markov_osc.js` | Node-for-Max OSC client/server |
| `package.json` | npm dependency on `node-osc` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `node-osc missing` error | Click **npm install** and wait for it to finish |
| Status stays `waiting` | Start Python (`python3 -m src.main` from `python/`) |
| `reply timeout` | Python not running, wrong port, or firewall blocking localhost UDP |
| `node.script` errors on load | Confirm Node for Max is enabled in Max 8 |

Run the Python smoke test without Max:

```bash
cd python
python3 scripts/osc_smoke_test.py --spawn-service
```

## OSC addresses

See [PLAN.md](../PLAN.md) and [docs/osc_contract.md](../docs/osc_contract.md).
