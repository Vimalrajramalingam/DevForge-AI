from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

# --- Auth Schemas ---
class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    created_at: str

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    password: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class TokenData(BaseModel):
    user_id: Optional[int] = None

# --- Project Schemas ---
class ProjectCreate(BaseModel):
    name: str
    description: str
    target_users: str
    budget: str
    timeline: str

class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_users: Optional[str] = None
    budget: Optional[str] = None
    timeline: Optional[str] = None

class ProjectResponse(BaseModel):
    id: int
    user_id: int
    name: str
    description: str
    target_users: str
    budget: str
    timeline: str
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True

# --- Report Schemas ---
class ReportResponse(BaseModel):
    id: int
    project_id: int
    agent_type: str
    content: str  # JSON stringified content
    created_at: str

    class Config:
        from_attributes = True

# --- AI Generator Schema ---
class AIGenerationResponse(BaseModel):
    agent_type: str
    content: Dict[str, Any]

# --- Chat Schemas ---
class ChatMessageCreate(BaseModel):
    message: str

class ChatMessageResponse(BaseModel):
    id: int
    project_id: int
    role: str
    message: str
    created_at: str

    class Config:
        from_attributes = True

class ChatResponse(BaseModel):
    user_message: ChatMessageResponse
    assistant_message: ChatMessageResponse

# --- Progress Schemas ---
class ProgressStageUpdate(BaseModel):
    stage: str
    completed: bool
    notes: Optional[str] = None

class ProgressStageResponse(BaseModel):
    stage: str
    completed: bool
    notes: Optional[str]
    updated_at: str

class ProjectProgressResponse(BaseModel):
    project_id: int
    stages: List[ProgressStageResponse]
    completion_percentage: float
    completed_count: int
    total_stages: int
    current_stage: Optional[str]
    next_recommended_step: Optional[str]

# --- Health Report Schemas ---
class HealthCategoryScore(BaseModel):
    category: str
    score: float
    max_score: float
    description: str
    color: str  # 'green', 'yellow', 'red'

class HealthReportResponse(BaseModel):
    project_id: int
    overall_score: float
    grade: str  # A, B, C, D, F
    categories: List[HealthCategoryScore]
    summary: str
    generated_at: str

# --- Improvement Suggestions Schemas ---
class ImprovementSuggestion(BaseModel):
    category: str
    priority: str  # 'high', 'medium', 'low'
    title: str
    description: str
    action_items: List[str]

class ImprovementsResponse(BaseModel):
    project_id: int
    suggestions: List[ImprovementSuggestion]
    generated_at: str

# --- Settings Schema ---
class SettingUpdate(BaseModel):
    key: str
    value: str

class SettingResponse(BaseModel):
    key: str
    value: str
    updated_at: str
