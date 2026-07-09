# OSC contract mirror — canonical spec is ../PLAN.md (protocol v2)

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

Default ports: Python `9000`, Max `9001`, host `127.0.0.1`.
