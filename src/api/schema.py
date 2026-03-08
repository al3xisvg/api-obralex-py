from fastapi import APIRouter, Query

from src.models.schema import ProductSchemaResponse, SchemaStatusResponse

from src.services import VertexAISearchService, InventorySchemaService

from src.core.config import Config

router = APIRouter()

_search_service = VertexAISearchService(
    project_id=Config.GCP_PROJECT_ID,
    location=Config.VERTEX_SEARCH_LOCATION,
    datastore_id=Config.VERTEX_SEARCH_DATASTORE_ID,
    collection=Config.VERTEX_SEARCH_COLLECTION,
)

_schema_service = InventorySchemaService(search_service=_search_service)


@router.get("/products/schema", response_model=ProductSchemaResponse)
async def get_product_schema(
    query: str = Query(..., min_length=1, description="Producto a buscar"),
):
    return _schema_service.get_schema_for_query(query)


@router.post("/schemas/reload")
async def reload_schemas():
    _schema_service.reload()
    return {"message": "Schemas reloaded"}


@router.get("/schemas/status", response_model=SchemaStatusResponse)
async def schemas_status():
    return _schema_service.status()
