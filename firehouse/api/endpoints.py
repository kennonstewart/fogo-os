from fastapi import APIRouter
from .health import router as health_router
from .register_face import router as register_face_router
from .analyze import router as analyze_router
from .stream_frame import router as stream_frame_router
from .results import router as results_router
from .admin import router as admin_router

router = APIRouter()

# Public routes
router.include_router(health_router, prefix="/health", tags=["system"])
router.include_router(register_face_router, prefix="/register-face", tags=["face"])
router.include_router(analyze_router, prefix="/analyze", tags=["analysis"])
router.include_router(stream_frame_router, prefix="/stream-frame", tags=["realtime"])
router.include_router(results_router, prefix="/results", tags=["analysis"])

# Admin-only routes
router.include_router(admin_router, prefix="/admin", tags=["admin"])