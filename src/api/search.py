from fastapi import APIRouter, Query

from src.models.search import (
    SearchResponse,
    SearchWithSummaryResponse,
    inventory_result_to_dict,
)

from src.services import VertexAISearchService

from src.core.config import Config

router = APIRouter()

_search_service = VertexAISearchService(
    project_id=Config.GCP_PROJECT_ID,
    location=Config.VERTEX_SEARCH_LOCATION,
    datastore_id=Config.VERTEX_SEARCH_DATASTORE_ID,
    collection=Config.VERTEX_SEARCH_COLLECTION,
)


@router.get("/search", response_model=SearchResponse)
async def search(
    q: str = Query(..., min_length=1, description="Search query"),
    page_size: int = Query(10, ge=1, le=50),
    offset: int = Query(0, ge=0),
):
    results = _search_service.search(query=q, page_size=page_size, offset=offset)
    return SearchResponse(
        query=q,
        total=len(results),
        results=[inventory_result_to_dict(r) for r in results],
    )


@router.get("/search/summary", response_model=SearchWithSummaryResponse)
async def search_with_summary(
    q: str = Query(..., min_length=1, description="Search query"),
    page_size: int = Query(10, ge=1, le=50),
):
    summary, results = _search_service.search_with_summary(query=q, page_size=page_size)
    return SearchWithSummaryResponse(
        query=q,
        summary=summary,
        total=len(results),
        results=[inventory_result_to_dict(r) for r in results],
    )
