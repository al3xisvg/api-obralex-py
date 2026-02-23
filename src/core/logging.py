import logging
import sys
import os


def setup_logging():
    """
    Configura el sistema de logging para toda la aplicación.

    - En local: formato legible con timestamp
    - En Cloud Run: formato simple para Cloud Logging
    """
    # Detectar si estamos en Cloud Run
    is_cloud_run = os.getenv("K_SERVICE") is not None

    # Configurar el formato según el entorno
    if is_cloud_run:
        log_format = "%(message)s"
    else:
        log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Limpiar handlers existentes y configurar desde cero
    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[logging.StreamHandler(sys.stdout)],
        force=True,  # Forzar reconfiguración (Python 3.8+)
    )

    # Asegurar que los loggers de la aplicación también logueen
    app_logger = logging.getLogger("src")
    app_logger.setLevel(logging.INFO)

    # Log de confirmación
    logging.info("🚀 Logging configurado correctamente")

    return app_logger
