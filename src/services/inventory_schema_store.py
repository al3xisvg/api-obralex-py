from google.cloud import storage
import logging
import time
import json

from src.core.config import Config

logger = logging.getLogger(__name__)


class InventorySchemaStore:
    def __init__(self):
        self._bucket_name = Config.GCS_BUCKET_KNOWLEDGE
        self._blob_path = Config.GCS_INVENTORY_SCHEMAS_PATH
        self._ttl = Config.GCS_TTL_SECONDS
        self._cache: dict | None = None
        self._loaded_at: float = 0
        self._client = storage.Client()

    def _is_expired(self) -> bool:
        return (time.time() - self._loaded_at) > self._ttl

    def _load_from_gcs(self) -> None:
        bucket = self._client.bucket(self._bucket_name)
        blob = bucket.blob(self._blob_path)
        content = blob.download_as_text()
        self._cache = json.loads(content)
        self._loaded_at = time.time()
        logger.info(
            "Schemas loaded from gs://%s/%s", self._bucket_name, self._blob_path
        )

    def get_schemas(self) -> dict:
        if self._cache is None or self._is_expired():
            try:
                self._load_from_gcs()
            except Exception:
                logger.exception("Failed to load schemas from GCS")
                if self._cache is not None:
                    return self._cache
                raise
        return self._cache

    def get_subcategory_schema(self, subcategory: str) -> dict | None:
        schemas = self.get_schemas()
        return schemas.get("subcategory_schemas", {}).get(subcategory)

    def get_category_schema(self, category: str) -> dict | None:
        schemas = self.get_schemas()
        return schemas.get("category_schemas", {}).get(category)

    def reload(self) -> dict:
        self._load_from_gcs()
        return self._cache

    def status(self) -> dict:
        schemas = self._cache or {}
        return {
            "loaded": self._cache is not None,
            "loaded_at": self._loaded_at,
            "ttl_seconds": self._ttl,
            "subcategory_count": len(schemas.get("subcategory_schemas", {})),
            "category_count": len(schemas.get("category_schemas", {})),
            "metadata": schemas.get("metadata"),
        }
