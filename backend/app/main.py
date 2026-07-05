from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse, HTMLResponse
from app.database import init_db
from app.routers import auth, projects, ai, chat
from app.config import settings
import os

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for DevForge AI - AI Software Development Companion",
    version="2.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def startup_event():
    init_db()

@app.get("/api/health")
def read_health():
    return {
        "message": "Welcome to DevForge AI API v2.0",
        "status": "online",
        "features": [
            "authentication",
            "projects",
            "ai_agents",
            "chat",
            "progress_tracker",
            "health_analyzer",
            "improvements"
        ]
    }

@app.get("/")
def read_root():
    static_file = os.path.join(os.path.dirname(__file__), "static", "index.html")
    if os.path.exists(static_file):
        return FileResponse(static_file)
    return HTMLResponse("<h1>DevForge AI API v2.0 - Running Successfully</h1><p>Visit <a href='/docs'>/docs</a> for API documentation.</p>")

# Register all routers
app.include_router(auth.router)
app.include_router(projects.router)
app.include_router(ai.router)
app.include_router(chat.router)

# Global error handler
@app.exception_handler(Exception)
def global_exception_handler(request: Request, exc: Exception):
    print(f"Global exception caught: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": f"An unexpected system error occurred: {str(exc)}"}
    )
