import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "DevForge AI"
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "DevForge_super_secret_jwt_key_9876543210")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 1 day
    
    # Database configuration
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", "DevForge.db")
    
    # Gemini Configuration
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    class Config:
        case_sensitive = True

settings = Settings()
