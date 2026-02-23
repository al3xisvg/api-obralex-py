import logging
import os

from src.core.config import Config

logger = logging.getLogger(__name__)


def is_cloud_run() -> bool:
    return os.getenv("K_SERVICE") is not None


def setup_gcp_credentials():
    if is_cloud_run():
        logger.info(
            "🌐 Detectado entorno Cloud Run - usando service account automático"
        )
        # En Cloud Run, las credenciales se manejan automáticamente
        # No necesitamos hacer nada
        return

    credentials_path = Config.GOOGLE_APPLICATION_CREDENTIALS

    if os.path.exists(credentials_path):
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = credentials_path
        logger.info(f"🔑 Entorno local - usando credenciales: {credentials_path}")
    else:
        logger.warning(f"⚠️  Archivo de credenciales no encontrado: {credentials_path}")
        logger.warning("   Si estás en local, verifica la ruta del archivo de llaves")
