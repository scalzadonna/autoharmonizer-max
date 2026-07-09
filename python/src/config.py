"""Configuration and OSC protocol constants (v3)."""

from __future__ import annotations

import argparse
import os
from dataclasses import dataclass
from pathlib import Path

PROTOCOL_VERSION = "v3"

# OSC addresses — keep in sync with PLAN.md and max/chord_generator_device.maxpat
OSC_CHORD_INPUT = "/chord/input"
OSC_CHORD_OUTPUT = "/chord/output"
OSC_STATUS_READY = "/status/ready"
OSC_STATUS_PONG = "/status/pong"
OSC_STATUS_MODEL = "/status/model"
OSC_STATUS_SESSION = "/status/session"
OSC_ERROR = "/error"
OSC_CONTROL_PING = "/control/ping"
OSC_CONTROL_RELOAD = "/control/reload"
OSC_CONTROL_MODEL = "/control/model"
OSC_CONTROL_SESSION = "/control/session"
OSC_DEBUG_PROBABILITY = "/debug/probability"
OSC_DEBUG_CANDIDATES = "/debug/candidates"
OSC_DEBUG_INPUT_ECHO = "/debug/input_echo"
OSC_DEBUG_FALLBACK_USED = "/debug/fallback_used"
OSC_DEBUG_MODEL = "/debug/model"
OSC_DEBUG_SESSION_HISTORY = "/debug/session_history"

FALLBACK_POLICIES = ("echo_input", "global_top", "random_source", "error_only")
DEFAULT_FALLBACK = "echo_input"

MODEL_NAMES = ("markov", "rnn", "lstm")
DEFAULT_MODEL = "markov"

DEFAULT_NEURAL_TEMPERATURE = 1.5
DEFAULT_NEURAL_EXCLUDE_INPUT = True

SESSION_MODES = ("auto", "stateless", "session")
DEFAULT_SESSION_MODE = "auto"
DEFAULT_SESSION_MAX_STEPS = 64
DEFAULT_SESSION_AUTO_FEED = True

PROB_SUM_TOLERANCE = 0.01


def repo_root() -> Path:
    """Return project root (directory containing PLAN.md)."""
    here = Path(__file__).resolve()
    for parent in [here.parent, *here.parents]:
        if (parent / "PLAN.md").exists():
            return parent
    return Path.cwd()


def resolve_csv_path(path: str | Path) -> Path:
    """Resolve CSV path relative to repo root when not found as given."""
    candidate = Path(path)
    if candidate.is_file():
        return candidate.resolve()

    from_root = repo_root() / path
    if from_root.is_file():
        return from_root.resolve()

    raise FileNotFoundError(f"CSV file not found: {path}")


def resolve_jazznet_dir(path: str | Path) -> Path:
    """Resolve JazzNet data directory relative to repo root when needed."""
    candidate = Path(path)
    if candidate.is_dir():
        return candidate.resolve()

    from_root = repo_root() / path
    if from_root.is_dir():
        return from_root.resolve()

    return candidate.resolve()


def _env_bool(name: str) -> bool | None:
    raw = os.environ.get(name)
    if raw is None:
        return None
    return raw.lower() in {"1", "true", "yes", "on"}


def _env_int(name: str) -> int | None:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return None
    return int(raw)


def _env_float(name: str) -> float | None:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return None
    return float(raw)


@dataclass(frozen=True)
class Settings:
    csv_path: Path
    jazznet_dir: Path
    jazznet_epoch: int
    model: str
    host: str
    port: int
    max_host: str
    max_port: int
    fallback: str
    debug: bool
    seed: int | None
    neural_temperature: float
    neural_exclude_input: bool
    session_mode: str
    session_max_steps: int
    session_auto_feed: bool


def build_parser() -> argparse.ArgumentParser:
    root = repo_root()
    default_csv = str(root / "data" / "markov_openbook.csv")
    default_jazznet = str(root / "data" / "jazznet")
    parser = argparse.ArgumentParser(description="Chord generator OSC service")
    parser.add_argument("--csv", default=default_csv, help="Path to Markov transition CSV")
    parser.add_argument(
        "--jazznet-dir",
        default=default_jazznet,
        help="JazzNet checkpoints and vocab directory",
    )
    parser.add_argument(
        "--jazznet-epoch",
        type=int,
        default=35,
        help="JazzNet checkpoint epoch",
    )
    parser.add_argument(
        "--model",
        choices=MODEL_NAMES,
        default=DEFAULT_MODEL,
        help="Active chord generation backend",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Bind host")
    parser.add_argument("--port", type=int, default=9000, help="Listen port")
    parser.add_argument("--max-host", default="127.0.0.1", help="Max reply host")
    parser.add_argument("--max-port", type=int, default=9001, help="Max reply port")
    parser.add_argument(
        "--fallback",
        choices=FALLBACK_POLICIES,
        default=DEFAULT_FALLBACK,
        help="Unknown chord fallback policy",
    )
    parser.add_argument("--debug", action="store_true", help="Emit debug OSC messages")
    parser.add_argument("--seed", type=int, default=None, help="Random seed for sampling")
    parser.add_argument(
        "--neural-temperature",
        type=float,
        default=DEFAULT_NEURAL_TEMPERATURE,
        help="Softmax temperature for RNN/LSTM sampling (>1 = more variety)",
    )
    parser.add_argument(
        "--neural-exclude-input",
        action=argparse.BooleanOptionalAction,
        default=DEFAULT_NEURAL_EXCLUDE_INPUT,
        help="Mask input chord token when sampling RNN/LSTM (force transition)",
    )
    parser.add_argument(
        "--session-mode",
        choices=SESSION_MODES,
        default=DEFAULT_SESSION_MODE,
        help="Session mode: auto (session for rnn/lstm), stateless, or session",
    )
    parser.add_argument(
        "--session-max-steps",
        type=int,
        default=DEFAULT_SESSION_MAX_STEPS,
        help="Auto-reset neural session after this many user chord steps",
    )
    parser.add_argument(
        "--session-auto-feed",
        action=argparse.BooleanOptionalAction,
        default=DEFAULT_SESSION_AUTO_FEED,
        help="Auto-feed model output token into session hidden state",
    )
    return parser


def load_settings(argv: list[str] | None = None) -> Settings:
    parser = build_parser()
    args = parser.parse_args(argv)

    csv_path = resolve_csv_path(os.environ.get("MARKOV_CSV", args.csv))
    jazznet_dir = resolve_jazznet_dir(os.environ.get("JAZZNET_DIR", args.jazznet_dir))
    jazznet_epoch = _env_int("JAZZNET_EPOCH") or args.jazznet_epoch
    model = os.environ.get("CHORD_MODEL", args.model)
    if model not in MODEL_NAMES:
        raise ValueError(f"Invalid model: {model}")

    host = os.environ.get("MARKOV_HOST", args.host)
    port = _env_int("MARKOV_PORT") or args.port
    max_host = os.environ.get("MARKOV_MAX_HOST", args.max_host)
    max_port = _env_int("MARKOV_MAX_PORT") or args.max_port
    fallback = os.environ.get("MARKOV_FALLBACK", args.fallback)
    if fallback not in FALLBACK_POLICIES:
        raise ValueError(f"Invalid fallback policy: {fallback}")

    debug_env = _env_bool("MARKOV_DEBUG")
    debug = debug_env if debug_env is not None else args.debug

    seed = _env_int("MARKOV_SEED")
    if seed is None:
        seed = args.seed

    neural_temperature = _env_float("NEURAL_TEMPERATURE")
    if neural_temperature is None:
        neural_temperature = args.neural_temperature
    if neural_temperature <= 0:
        raise ValueError(f"neural temperature must be > 0, got {neural_temperature}")

    exclude_env = _env_bool("NEURAL_EXCLUDE_INPUT")
    neural_exclude_input = (
        exclude_env if exclude_env is not None else args.neural_exclude_input
    )

    session_mode = os.environ.get("SESSION_MODE", args.session_mode)
    if session_mode not in SESSION_MODES:
        raise ValueError(f"Invalid session mode: {session_mode}")

    session_max_steps = _env_int("SESSION_MAX_STEPS")
    if session_max_steps is None:
        session_max_steps = args.session_max_steps
    if session_max_steps <= 0:
        raise ValueError(f"session max steps must be > 0, got {session_max_steps}")

    auto_feed_env = _env_bool("SESSION_AUTO_FEED")
    session_auto_feed = (
        auto_feed_env if auto_feed_env is not None else args.session_auto_feed
    )

    if host != "127.0.0.1":
        raise ValueError("v3 requires binding to 127.0.0.1 only")

    return Settings(
        csv_path=csv_path,
        jazznet_dir=jazznet_dir,
        jazznet_epoch=jazznet_epoch,
        model=model,
        host=host,
        port=port,
        max_host=max_host,
        max_port=max_port,
        fallback=fallback,
        debug=debug,
        seed=seed,
        neural_temperature=neural_temperature,
        neural_exclude_input=neural_exclude_input,
        session_mode=session_mode,
        session_max_steps=session_max_steps,
        session_auto_feed=session_auto_feed,
    )
