"""Entry point for the chord generator OSC service."""

from __future__ import annotations

import logging
import signal

from .config import PROTOCOL_VERSION, load_settings
from .csv_loader import CSVLoadError
from .osc_service import ChordOscService


def configure_logging(debug: bool) -> None:
    level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )


def main(argv: list[str] | None = None) -> int:
    settings = load_settings(argv)
    configure_logging(settings.debug)
    logger = logging.getLogger(__name__)
    logger.info("starting chord service protocol=%s", PROTOCOL_VERSION)
    logger.info(
        "config model=%s csv=%s jazznet=%s epoch=%s host=%s port=%s max=%s:%s "
        "fallback=%s seed=%s neural_temp=%s neural_exclude_input=%s "
        "session_mode=%s session_max_steps=%s session_auto_feed=%s debug=%s",
        settings.model,
        settings.csv_path,
        settings.jazznet_dir,
        settings.jazznet_epoch,
        settings.host,
        settings.port,
        settings.max_host,
        settings.max_port,
        settings.fallback,
        settings.seed,
        settings.neural_temperature,
        settings.neural_exclude_input,
        settings.session_mode,
        settings.session_max_steps,
        settings.session_auto_feed,
        settings.debug,
    )

    service = ChordOscService(settings)

    def _shutdown(_signum: int, _frame: object) -> None:
        logger.info("shutting down")
        service.stop()

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    try:
        service.run_forever()
    except CSVLoadError as exc:
        logger.error("startup failed: %s", exc)
        return 1
    except OSError as exc:
        logger.error("server error: %s", exc)
        return 1
    except KeyboardInterrupt:
        logger.info("interrupted")
    finally:
        service.stop()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
