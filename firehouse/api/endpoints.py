from fastapi import APIRouter
from .analyze import router as analyze_router
from .status import router as status_router
from .admin import router as admin_router

router = APIRouter()
router.include_router(analyze_router)
router.include_router(status_router)
router.include_router(admin_router, prefix="/admin", tags=["admin"])