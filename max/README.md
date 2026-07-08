# Chord Markov Max Device (protocol v1)

Standalone Max/MSP patch that sends chord symbols to the Python Markov OSC service and displays the sampled reply.

## Requirements

- Max 8+
- [CNMAT OSC externals](https://github.com/CNMAT/CNMAT-Externs) (`o.pack`, `o.route`)
- Python service running locally (see below)

## Quick start

1. Install Python dependencies and start the service from the repo root:

```bash
cd python
pip install -r requirements.txt
python -m src.main
```

2. Open `chord_markov_device.maxpat` in Max.

3. Click **ping** — status should show **ready** when `/status/pong` is received.

4. Enter a chord (e.g. `G:7`) and click **send** — output appears when `/chord/output` arrives.

5. Click **reload** to reload the CSV without restarting Python.

## Default ports

| Role | Host | Port |
|---|---|---|
| Python listen | `127.0.0.1` | `9000` |
| Max listen | `127.0.0.1` | `9001` |

Change the `udpsend` / `udpreceive` objects if you use non-default ports.

## Controls

| UI | Action |
|---|---|
| **ping** | Sends `/control/ping` |
| **send** | Sends `/chord/input` with the text field value |
| **reload** | Sends `/control/reload` |
| status | Shows `ready` after pong/ready; `waiting` otherwise |
| output | Last `/chord/output` chord symbol |
| error | Last `/error` or `reply timeout` after 500 ms |

## OSC addresses

See [PLAN.md](../PLAN.md) and [docs/osc_contract.md](../docs/osc_contract.md).

## Troubleshooting

- **No ready status**: confirm Python is running (`python -m src.main` from `python/`).
- **reply timeout**: Python not running, wrong port, or CNMAT OSC pack/route mismatch.
- **CNMAT missing**: install CNMAT externals; do not send raw strings via `udpsend` alone.

Run the Python smoke test without Max:

```bash
cd python
python scripts/osc_smoke_test.py --spawn-service
```
