import json
import httpx
from typing import Dict, Any, List, Optional
from app.config import settings

# ─────────────────────────────────────────────────────────
#  Core Gemini API caller
# ─────────────────────────────────────────────────────────

def call_gemini_api(prompt: str, json_mode: bool = True) -> str:
    """Calls the Gemini 1.5 Flash REST endpoint via HTTPX."""
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY not configured")

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={settings.GEMINI_API_KEY}"
    headers = {"Content-Type": "application/json"}
    payload: Dict[str, Any] = {
        "contents": [{"parts": [{"text": prompt}]}],
    }
    if json_mode:
        payload["generationConfig"] = {"responseMimeType": "application/json"}

    try:
        response = httpx.post(url, headers=headers, json=payload, timeout=60.0)
        response.raise_for_status()
        result = response.json()
        text = result["candidates"][0]["content"]["parts"][0]["text"]
        return text
    except Exception as e:
        print(f"Error calling Gemini API: {str(e)}")
        raise e

# ─────────────────────────────────────────────────────────
#  Report Generation (existing feature, preserved)
# ─────────────────────────────────────────────────────────

def generate_report(project: Dict[str, Any], agent_type: str) -> Dict[str, Any]:
    """Generate a report for a specific agent type."""
    p_name = project.get("name", "Unnamed Project")
    p_desc = project.get("description", "No description")
    p_users = project.get("target_users", "All users")
    p_budget = project.get("budget", "Flexible")
    p_timeline = project.get("timeline", "Flexible")

    if settings.GEMINI_API_KEY:
        prompt = get_agent_prompt(p_name, p_desc, p_users, p_budget, p_timeline, agent_type)
        try:
            raw_response = call_gemini_api(prompt, json_mode=True)
            if raw_response.strip().startswith("```json"):
                raw_response = raw_response.strip()[7:-3]
            elif raw_response.strip().startswith("```"):
                raw_response = raw_response.strip()[3:-3]
            return json.loads(raw_response)
        except Exception as ex:
            print(f"Fallback to simulation due to API error: {str(ex)}")
            return get_simulated_report(p_name, p_desc, p_users, p_budget, p_timeline, agent_type)
    else:
        return get_simulated_report(p_name, p_desc, p_users, p_budget, p_timeline, agent_type)

# ─────────────────────────────────────────────────────────
#  Chat Response Generation
# ─────────────────────────────────────────────────────────

def generate_chat_response(
    project: Dict[str, Any],
    user_message: str,
    chat_history: List[Dict[str, str]],
    available_reports: List[str]
) -> str:
    """Generate a context-aware chat response for the DevForge AI assistant."""
    p_name = project.get("name", "Unnamed Project")
    p_desc = project.get("description", "No description")
    p_users = project.get("target_users", "All users")
    p_budget = project.get("budget", "Flexible")
    p_timeline = project.get("timeline", "Flexible")

    reports_context = ", ".join(available_reports) if available_reports else "none yet"

    history_text = ""
    if chat_history:
        history_lines = []
        for msg in chat_history[-8:]:  # Last 8 messages for context
            role_label = "User" if msg["role"] == "user" else "DevForge AI"
            history_lines.append(f"{role_label}: {msg['message']}")
        history_text = "\n".join(history_lines)

    prompt = f"""You are DevForge AI, an expert AI Software Development Companion. You are currently helping with this specific project:

PROJECT CONTEXT:
- Name: {p_name}
- Description: {p_desc}
- Target Users: {p_users}
- Budget: {p_budget}
- Timeline: {p_timeline}
- Generated Reports Available: {reports_context}

You are an expert in: Flutter, FastAPI, SQLite, REST API design, Software Architecture, Database Design, Authentication (JWT/OAuth), Testing, DevOps, and Software Engineering best practices.

CONVERSATION HISTORY:
{history_text}

USER'S CURRENT MESSAGE: {user_message}

INSTRUCTIONS:
- Answer directly and specifically for this project context
- If asked about code, provide working code examples relevant to this project
- If asked about architecture, refer to the project's tech stack
- Be concise but thorough
- Use markdown formatting for code blocks and lists
- If the question is outside software development, gently redirect to technical topics
- Never say you cannot help with software-related questions

Your response:"""

    if settings.GEMINI_API_KEY:
        try:
            response = call_gemini_api(prompt, json_mode=False)
            return response.strip()
        except Exception as ex:
            print(f"Chat API fallback: {str(ex)}")
            return get_simulated_chat_response(p_name, user_message)
    else:
        return get_simulated_chat_response(p_name, user_message)


def get_simulated_chat_response(project_name: str, user_message: str) -> str:
    """High-quality simulated chat responses for demo mode."""
    msg_lower = user_message.lower()

    if any(word in msg_lower for word in ["flutter", "dart", "widget", "screen", "ui"]):
        return f"""## Flutter Guidance for {project_name}

For your Flutter frontend, here's a recommended approach:

```dart
// Example: Clean state management with Provider
class ProjectProvider extends ChangeNotifier {{
  List<Project> _projects = [];
  
  Future<void> loadProjects() async {{
    final response = await apiClient.get('/api/projects');
    if (response.statusCode == 200) {{
      _projects = (jsonDecode(response.body) as List)
          .map((j) => Project.fromJson(j))
          .toList();
      notifyListeners();
    }}
  }}
}}
```

**Best practices for {project_name}:**
- Use `Consumer<T>` widgets to rebuild only affected UI components
- Implement `dispose()` to prevent memory leaks in `StatefulWidget`s
- Use `const` constructors wherever possible for performance
- Separate business logic from UI using the MVVM pattern

Would you like me to explain a specific Flutter concept in more detail?"""

    elif any(word in msg_lower for word in ["fastapi", "api", "endpoint", "rest", "backend"]):
        return f"""## FastAPI Development for {project_name}

Here's a production-ready endpoint pattern:

```python
from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user

router = APIRouter(prefix="/api/{project_name.lower().replace(' ', '_')}", tags=["main"])

@router.get("/items", response_model=list[ItemResponse])
def list_items(
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT * FROM items WHERE user_id = ?",
            (current_user.id,)
        )
        return [ItemResponse(**dict(row)) for row in cursor.fetchall()]
```

**Key FastAPI principles:**
- Always use `Depends(get_current_user)` for protected routes
- Use Pydantic models for request/response validation
- Handle database errors with proper try/except blocks
- Return appropriate HTTP status codes

What specific endpoint would you like help designing?"""

    elif any(word in msg_lower for word in ["database", "sql", "table", "schema", "sqlite"]):
        return f"""## Database Design for {project_name}

Here's an optimized SQLite schema pattern:

```sql
-- Core tables with proper foreign keys and indexes
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS {project_name.lower().replace(' ', '_')}_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'inactive', 'archived')),
    metadata TEXT, -- Store JSON for flexible fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_items_user ON {project_name.lower().replace(' ', '_')}_items(user_id);
CREATE INDEX IF NOT EXISTS idx_items_status ON {project_name.lower().replace(' ', '_')}_items(status);
```

**SQLite optimization tips:**
- Enable WAL mode: `PRAGMA journal_mode=WAL;`
- Enable foreign keys: `PRAGMA foreign_keys=ON;`
- Use appropriate column types (TEXT for flexible data)
- Index columns used in WHERE clauses

Need help with a specific query or relationship?"""

    elif any(word in msg_lower for word in ["auth", "jwt", "token", "login", "security"]):
        return f"""## Authentication & Security for {project_name}

Your JWT authentication flow:

```python
# Token creation
def create_access_token(user_id: int) -> str:
    payload = {{
        "sub": str(user_id),
        "exp": datetime.utcnow() + timedelta(hours=24),
        "iat": datetime.utcnow()
    }}
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# Protected route dependency
def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user_id = int(payload.get("sub"))
        # Fetch user from DB...
    except jwt.ExpiredSignatureError:
        raise HTTPException(401, "Token expired")
    except jwt.PyJWTError:
        raise HTTPException(401, "Invalid token")
```

**Security checklist for {project_name}:**
- ✅ Use bcrypt for password hashing (never MD5/SHA1)
- ✅ JWT tokens with expiration
- ✅ HTTPS in production
- ⚠️ Add rate limiting to auth endpoints
- ⚠️ Implement refresh token rotation
- ⚠️ Add input sanitization

Would you like help implementing any of these security measures?"""

    elif any(word in msg_lower for word in ["architecture", "design", "pattern", "structure"]):
        return f"""## Architecture Recommendations for {project_name}

**Recommended Clean Architecture:**

```
{project_name}/
├── backend/                 # FastAPI Python API
│   ├── app/
│   │   ├── routers/        # API endpoints (auth, items, etc.)
│   │   ├── services/       # Business logic layer
│   │   ├── models/         # Database models
│   │   ├── schemas.py      # Pydantic request/response schemas
│   │   ├── auth.py         # JWT authentication utilities
│   │   └── database.py     # SQLite connection manager
│   └── main.py
│
└── frontend/               # Flutter application
    └── lib/
        ├── core/           # Theme, API client, constants
        ├── models/         # Data models (mirroring API schemas)
        ├── providers/      # State management (Provider pattern)
        ├── screens/        # Full page views
        └── widgets/        # Reusable UI components
```

**Design Patterns Applied:**
- **Repository Pattern**: Separate data access from business logic
- **Provider Pattern**: Reactive state management in Flutter
- **Dependency Injection**: FastAPI `Depends()` for clean coupling
- **MVVM**: Model-View-ViewModel in Flutter screens

What specific architectural decision do you need guidance on?"""

    elif any(word in msg_lower for word in ["test", "testing", "unit", "integration"]):
        return f"""## Testing Strategy for {project_name}

**Backend Testing (pytest + FastAPI TestClient):**

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_login_success():
    response = client.post("/api/auth/login", json={{
        "email": "test@example.com",
        "password": "TestPass123"
    }})
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_create_project_authenticated():
    # First login to get token
    login_resp = client.post("/api/auth/login", json={{
        "email": "test@example.com",
        "password": "TestPass123"
    }})
    token = login_resp.json()["access_token"]
    
    response = client.post(
        "/api/projects",
        json={{"name": "Test", "description": "Test project", 
               "target_users": "Devs", "budget": "$1k", "timeline": "1 month"}},
        headers={{"Authorization": f"Bearer {{token}}"}}
    )
    assert response.status_code == 200
```

**Flutter Testing:**
```dart
testWidgets('Login screen shows error on invalid credentials', (tester) async {{
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  expect(find.text('Please enter your email'), findsOneWidget);
}});
```

What specific test scenario would you like help with?"""

    else:
        # A simple keyword matcher to answer almost any technical or general query dynamically
        if "hello" in msg_lower or "hi" in msg_lower or "hey" in msg_lower:
            return f"Hello! I am your DevForge AI Assistant. I have read the project context for **{project_name}** and am ready to help you plan, build, design, or test your software. Ask me anything!"
        elif "budget" in msg_lower or "cost" in msg_lower:
            return f"Regarding the budget constraints of **{project_name}**, we should prioritize standard SQLite operations, free tier hosting (Render/Railway), and use local caching strategies to keep development costs to a minimum."
        elif "time" in msg_lower or "timeline" in msg_lower or "sprint" in msg_lower:
            return f"To meet the timeline goals of **{project_name}**, I suggest running in structured 2-week sprints. Start with establishing database schemas, then API endpoints, and finally the Flutter UI integration. Let me know if you want a detailed checklist!"
        elif "help" in msg_lower or "what can" in msg_lower:
            return f"I can assist you with your project **{project_name}** by answering questions about:\n\n- 🏗️ Architecture design decisions\n- 💻 Flutter widget building & providers\n- ⚙️ FastAPI routes, schemas, and logic\n- 🗄️ SQLite schemas & ER diagrams\n- 🔐 JWT authentication & security\n- 🧪 Testing & mock validation"
        else:
            # Dynamic response fallback based on the user's specific text
            trimmed_msg = user_message.trim() if hasattr(user_message, 'trim') else user_message.strip()
            return f"""### DevForge AI Response for {project_name}

You asked: *"{trimmed_msg}"*

Here is my recommendation for your project:
1. **Best Practice:** Keep modules decoupled. Separate business logic from UI controllers.
2. **Implementation:** Since we are using FastAPI and Flutter, we should leverage Pydantic models on the backend and Provider state notifiers on the frontend to process this flow safely.
3. **Action Step:** To implement this, write a helper service in Python under `app/services/` and integrate it via a dedicated route handler.

Is there any specific code snippet or error message related to this you'd like me to debug?"""


# ─────────────────────────────────────────────────────────
#  Improvements Generation
# ─────────────────────────────────────────────────────────

def generate_improvements(
    project: Dict[str, Any],
    available_reports: List[str]
) -> List[Dict[str, Any]]:
    """Generate improvement suggestions based on project analysis."""
    p_name = project.get("name", "Project")
    p_desc = project.get("description", "")
    p_budget = project.get("budget", "Flexible")
    p_timeline = project.get("timeline", "Flexible")

    if settings.GEMINI_API_KEY:
        reports_summary = ", ".join(available_reports) if available_reports else "none"
        prompt = f"""Analyze this software project and generate specific improvement suggestions:

Project: {p_name}
Description: {p_desc}
Budget: {p_budget}
Timeline: {p_timeline}
Generated Reports: {reports_summary}

Return a JSON array of improvement suggestions. Each suggestion must have:
{{
  "category": "Security|Architecture|Database|API|Testing|Documentation|Performance|DevOps",
  "priority": "high|medium|low",
  "title": "Short improvement title",
  "description": "Detailed description of the improvement",
  "action_items": ["Step 1", "Step 2", "Step 3"]
}}

Provide 6-8 concrete, actionable suggestions specific to this project. Return only the JSON array."""

        try:
            raw = call_gemini_api(prompt, json_mode=True)
            if raw.strip().startswith("```"):
                raw = raw.strip().split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                return parsed
        except Exception as ex:
            print(f"Improvements AI fallback: {str(ex)}")

    return get_simulated_improvements(p_name, p_desc, p_budget, p_timeline, available_reports)


def get_simulated_improvements(
    name: str, desc: str, budget: str, timeline: str, reports: List[str]
) -> List[Dict[str, Any]]:
    """High-quality simulated improvement suggestions."""
    suggestions = []

    if "risk" not in reports:
        suggestions.append({
            "category": "Security",
            "priority": "high",
            "title": "Implement Comprehensive Security Analysis",
            "description": f"Your project '{name}' currently lacks a formal security risk assessment. Security vulnerabilities discovered late in development are significantly more expensive to fix.",
            "action_items": [
                "Run the Risk Analyzer agent to identify security gaps",
                "Implement input validation and sanitization on all API endpoints",
                "Add rate limiting to authentication endpoints (max 5 attempts/minute)",
                "Configure HTTPS and secure headers for production deployment",
                "Store sensitive configuration in environment variables, never in code"
            ]
        })

    if "architecture" not in reports:
        suggestions.append({
            "category": "Architecture",
            "priority": "high",
            "title": "Define System Architecture Before Development",
            "description": f"No architecture document exists for '{name}'. Starting development without a clear architecture leads to technical debt and costly refactoring later.",
            "action_items": [
                "Run the Architecture Generator to create a formal system design",
                "Define clear service boundaries and responsibilities",
                "Choose and document your design pattern (MVVM, Clean Architecture, etc.)",
                "Create a component diagram showing how modules communicate",
                "Plan for scalability from the beginning"
            ]
        })

    if "test" not in reports:
        suggestions.append({
            "category": "Testing",
            "priority": "high",
            "title": "Establish Testing Strategy Early",
            "description": f"'{name}' has no test cases defined. Projects without testing strategy have 40% higher bug rates in production.",
            "action_items": [
                "Run the Test Case Generator agent",
                "Implement unit tests for all business logic functions",
                "Add integration tests for all API endpoints",
                "Set up automated testing in your CI/CD pipeline",
                "Aim for minimum 80% code coverage on critical paths"
            ]
        })

    if "docs" not in reports:
        suggestions.append({
            "category": "Documentation",
            "priority": "medium",
            "title": "Generate Comprehensive Project Documentation",
            "description": f"Documentation for '{name}' is missing. Good documentation reduces onboarding time by 50% and prevents knowledge silos.",
            "action_items": [
                "Run the Documentation Generator agent",
                "Write a detailed README with setup instructions",
                "Document all API endpoints with request/response examples",
                "Create an architecture decision records (ADR) document",
                "Add inline code comments for complex business logic"
            ]
        })

    suggestions.append({
        "category": "Performance",
        "priority": "medium",
        "title": "Optimize Database Query Performance",
        "description": f"As '{name}' scales, unoptimized database queries become the primary bottleneck. Proactive optimization prevents performance issues.",
        "action_items": [
            "Add database indexes on all foreign keys and frequently queried columns",
            "Enable WAL mode in SQLite: PRAGMA journal_mode=WAL",
            "Implement query pagination to avoid loading large datasets",
            "Use connection pooling for concurrent request handling",
            "Profile slow queries using SQLite EXPLAIN QUERY PLAN"
        ]
    })

    suggestions.append({
        "category": "DevOps",
        "priority": "medium",
        "title": "Set Up Continuous Integration Pipeline",
        "description": f"Automating the build and test pipeline for '{name}' ensures code quality and enables faster, safer deployments.",
        "action_items": [
            "Configure GitHub Actions workflow for automated testing",
            "Add pre-commit hooks for code formatting and linting",
            "Set up Docker containerization for consistent deployments",
            "Configure environment-specific settings (.env files)",
            "Implement health check endpoints for monitoring"
        ]
    })

    suggestions.append({
        "category": "API",
        "priority": "low",
        "title": "Implement API Versioning and Rate Limiting",
        "description": f"Future-proof '{name}' API by adding versioning from the start. Breaking API changes without versioning frustrates users.",
        "action_items": [
            "Prefix all endpoints with version: /api/v1/",
            "Add SlowAPI rate limiting middleware to FastAPI",
            "Implement request/response logging for debugging",
            "Add Swagger/OpenAPI documentation with examples",
            "Define and document error codes consistently across all endpoints"
        ]
    })

    suggestions.append({
        "category": "Architecture",
        "priority": "low",
        "title": "Implement Caching Layer for Frequent Operations",
        "description": f"Adding caching to '{name}' can reduce database load by 70% for read-heavy operations.",
        "action_items": [
            "Identify frequently accessed, rarely changed data (user profiles, project lists)",
            "Implement in-memory caching using functools.lru_cache for simple cases",
            "Consider Redis for distributed caching as the app scales",
            "Cache AI generation results to avoid redundant API calls",
            "Implement cache invalidation strategy when data changes"
        ]
    })

    return suggestions

# ─────────────────────────────────────────────────────────
#  Agent Prompts (existing, preserved)
# ─────────────────────────────────────────────────────────

def get_agent_prompt(name: str, desc: str, users: str, budget: str, timeline: str, agent_type: str) -> str:
    base_info = f"Project Name: {name}\nDescription: {desc}\nTarget Users: {users}\nBudget: {budget}\nTimeline: {timeline}\n\n"

    if agent_type == "requirements":
        return base_info + """Generate the project requirements. You must return a JSON object with the following keys and data types:
{
  "goals": ["Goal 1", "Goal 2"],
  "objectives": ["Business Objective 1", "Business Objective 2"],
  "functional": ["Functional Req 1", "Functional Req 2"],
  "non_functional": ["Non Functional Req 1", "Non Functional Req 2"],
  "scope": ["In-scope 1", "In-scope 2"]
}
Ensure all descriptions are professional, extensive, and tailored to the project details."""

    elif agent_type == "architecture":
        return base_info + """Generate the system architecture. You must return a JSON object:
{
  "system_design": "Detailed system architecture overview...",
  "tech_stack": [{"category": "Frontend", "tech": "Flutter"}, {"category": "Backend", "tech": "FastAPI"}],
  "folder_structure": "lib/\\n  core/\\n  models/\\n",
  "workflow": ["Step 1: User logs in", "Step 2: API triggers..."],
  "suggestions": ["Docker containerization", "Redis caching"]
}"""

    elif agent_type == "database":
        return base_info + """Generate the database design. You must return a JSON object:
{
  "er_diagram": "erDiagram\\n USER ||--o{ PROJECT : creates\\n",
  "tables": [
    {
      "name": "users",
      "columns": ["id INT PRIMARY KEY AUTOINCREMENT", "email VARCHAR(255) UNIQUE NOT NULL"],
      "relationships": ["One-to-many relationship with projects"]
    }
  ],
  "indexes": ["CREATE INDEX idx_users_email ON users(email);"],
  "sql_script": "CREATE TABLE users (\\n  id INTEGER PRIMARY KEY...\\n);"
}"""

    elif agent_type == "api":
        return base_info + """Generate REST API endpoints. You must return a JSON object:
{
  "endpoints": [
    {
      "path": "/api/v1/auth/login",
      "method": "POST",
      "description": "Authenticate user credentials",
      "request_body": "{\\n  \\"email\\": \\"string\\"\\n}",
      "response": "{\\n  \\"token\\": \\"string\\"\\n}"
    }
  ],
  "error_handling": [
    {"code": 400, "message": "Bad Request - Invalid Parameters"},
    {"code": 401, "message": "Unauthorized - Invalid Token"}
  ]
}"""

    elif agent_type == "ui":
        return base_info + """Generate UI details. You must return a JSON object:
{
  "screens": [
    {
      "name": "Dashboard",
      "description": "Primary screen displaying project statistics.",
      "components": ["Side Navigation Bar", "Stats Widgets"],
      "navigation": ["Navigate to Settings"]
    }
  ],
  "palette": {
    "primary": "#3F51B5",
    "secondary": "#FF4081",
    "background": "#F5F5F5",
    "accent": "#00E676"
  },
  "typography": ["Header: Outfit Bold 24sp", "Body: Inter Regular 14sp"]
}"""

    elif agent_type == "test":
        return base_info + """Generate software test cases. You must return a JSON object:
{
  "unit_tests": ["Test authentication token validation"],
  "integration_tests": ["Verify API endpoint /project returns DB saved elements"],
  "edge_cases": ["Attempting login with empty username"],
  "performance": ["Simulate 10,000 concurrent database reads"]
}"""

    elif agent_type == "docs":
        return base_info + """Generate project documentation. You must return a JSON object:
{
  "readme": "# Project Title\\nDetailed README file...",
  "install_guide": "## Step-by-Step Installation\\n1. Clone code\\n",
  "deployment": "## Deployment Process\\n1. Docker build\\n"
}"""

    elif agent_type == "risk":
        return base_info + """Generate risk evaluation. You must return a JSON object:
{
  "risks": [
    {
      "category": "Technical",
      "risk": "High database load during peak cycles",
      "mitigation": "Introduce Redis cache layers"
    }
  ]
}"""

    elif agent_type == "tasks":
        return base_info + """Generate development sprints. You must return a JSON object:
{
  "milestones": ["Milestone 1: Backend architecture configured"],
  "sprint_plan": [
    {
      "sprint": "Sprint 1: Architecture & DB Setup",
      "duration": 2,
      "tasks": ["Design ER diagram", "Initialize tables"]
    }
  ],
  "kanban": {
    "todo": ["Implement dark mode switch"],
    "in_progress": ["Implement OAuth token verification"],
    "done": ["Set up FastAPI skeleton"]
  }
}"""

    return base_info + "Provide a generic project summary in JSON."

# ─────────────────────────────────────────────────────────
#  Simulated Report Data (existing, preserved + enhanced)
# ─────────────────────────────────────────────────────────

def get_simulated_report(name: str, desc: str, users: str, budget: str, timeline: str, agent_type: str) -> Dict[str, Any]:
    """High-quality simulated reports for demo mode."""
    if agent_type == "requirements":
        return {
            "goals": [
                f"Develop a robust and scalable MVP for {name} targeting {users}.",
                "Establish a secure and modular system architecture for rapid iterations.",
                "Ensure high performance and smooth responsiveness across platforms."
            ],
            "objectives": [
                f"Launch version 1.0 within the specified timeline of {timeline}.",
                f"Optimize development lifecycle to align with the {budget} budget constraints.",
                "Acquire early adopter feedback to guide future sprints."
            ],
            "functional": [
                "User account registration, authentication, and secure password recovery.",
                f"Core service: {desc[:120]}...",
                "Workspace collaboration: allow sharing and role configuration.",
                "Real-time notifications dashboard for action updates.",
                "CSV/PDF and Markdown report generation and export."
            ],
            "non_functional": [
                "Performance: page load speeds under 2.5 seconds on standard connections.",
                "Security: password encryption using BCrypt and authorization using HS256 JWT.",
                "Reliability: SQLite snapshotting backups executed daily with 99.9% uptime SLA.",
                "Scale: horizontal scaling potential on containerized backend nodes."
            ],
            "scope": [
                "User Account Portal & Security Settings",
                "Primary Project Dashboard with analytics",
                "Report Generation & Exports Engine",
                "AI Agent Integration Layer",
                "Out-of-scope for Phase 1: Native Mobile App push notifications."
            ]
        }
    elif agent_type == "architecture":
        return {
            "system_design": f"Clean architecture for {name}. Consists of a responsive Flutter application interacting with a Python FastAPI REST API. The API processes requests, writes to a SQLite transactional database, and is containerized via Docker for portable deployments. The authentication system uses stateless JSON Web Tokens (HS256). The Flutter frontend uses the Provider pattern for reactive state management following MVVM principles.",
            "tech_stack": [
                {"category": "Frontend", "tech": "Flutter (Dart) / Material 3 / Provider"},
                {"category": "Backend", "tech": "FastAPI (Python 3.10+) / Uvicorn ASGI"},
                {"category": "Database", "tech": "SQLite3 / WAL Mode / Foreign Key Constraints"},
                {"category": "AI Integration", "tech": "Google Gemini 1.5 Flash API"},
                {"category": "Deployment", "tech": "Docker / Docker-Compose / GitHub Actions CI/CD"}
            ],
            "folder_structure": f"/{name.lower().replace(' ', '_')}\n├── backend/\n│   ├── app/\n│   │   ├── main.py\n│   │   ├── database.py\n│   │   ├── auth.py\n│   │   ├── schemas.py\n│   │   ├── config.py\n│   │   ├── routers/\n│   │   │   ├── auth.py\n│   │   │   ├── projects.py\n│   │   │   ├── ai.py\n│   │   │   └── chat.py\n│   │   └── services/\n│   │       └── gemini.py\n│   ├── requirements.txt\n│   └── Dockerfile\n└── frontend/\n    ├── lib/\n    │   ├── main.dart\n    │   ├── core/\n    │   │   ├── theme.dart\n    │   │   └── api_client.dart\n    │   ├── models/\n    │   ├── providers/\n    │   ├── screens/\n    │   └── widgets/\n    └── pubspec.yaml",
            "workflow": [
                "1. User initiates a request in Flutter UI.",
                "2. HTTP Client attaches JWT Bearer token and triggers FastAPI endpoint.",
                "3. FastAPI validates token, parses request body, performs database transaction.",
                "4. If AI generation requested, Gemini API is called with project context.",
                "5. Response is returned as JSON and mapped into Flutter Provider state models.",
                "6. View re-renders with fresh details using smooth animations."
            ],
            "suggestions": [
                "Integrate Redis caching for frequently visited dashboard data to reduce SQLite load.",
                "Deploy on AWS Lightsail or DigitalOcean Droplets with an Nginx reverse proxy.",
                "Consider migrating to PostgreSQL when concurrent writes exceed 100/second."
            ]
        }
    elif agent_type == "database":
        prefix = name.lower().replace(" ", "_")
        return {
            "er_diagram": f"erDiagram\n  users ||--o{{ projects : creates\n  projects ||--o{{ {prefix}_items : stores\n  projects ||--o{{ reports : generates\n  projects ||--o{{ chat_history : contains\n  users ||--o{{ sessions : logs",
            "tables": [
                {
                    "name": "users",
                    "columns": ["id INTEGER PRIMARY KEY AUTOINCREMENT", "email TEXT UNIQUE NOT NULL", "password_hash TEXT NOT NULL", "full_name TEXT NOT NULL", "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"],
                    "relationships": ["One-to-many relationship with projects (user_id → users.id)"]
                },
                {
                    "name": "projects",
                    "columns": ["id INTEGER PRIMARY KEY AUTOINCREMENT", "user_id INTEGER NOT NULL", "name TEXT NOT NULL", "description TEXT", "budget TEXT", "timeline TEXT", "target_users TEXT", "created_at TIMESTAMP", "updated_at TIMESTAMP"],
                    "relationships": ["Foreign key references users.id", "One-to-many with reports", "One-to-many with chat_history"]
                },
                {
                    "name": f"{prefix}_items",
                    "columns": ["id INTEGER PRIMARY KEY AUTOINCREMENT", "project_id INTEGER NOT NULL", "title TEXT NOT NULL", "status TEXT DEFAULT 'todo' CHECK(status IN ('todo','in_progress','done'))", "priority TEXT DEFAULT 'medium'", "details TEXT", "created_at TIMESTAMP"],
                    "relationships": ["Foreign key references projects.id ON DELETE CASCADE"]
                },
                {
                    "name": "chat_history",
                    "columns": ["id INTEGER PRIMARY KEY AUTOINCREMENT", "project_id INTEGER NOT NULL", "user_id INTEGER NOT NULL", "role TEXT NOT NULL CHECK(role IN ('user','assistant'))", "message TEXT NOT NULL", "created_at TIMESTAMP"],
                    "relationships": ["Foreign key references projects.id ON DELETE CASCADE"]
                }
            ],
            "indexes": [
                "CREATE INDEX idx_users_email ON users(email);",
                f"CREATE INDEX idx_items_project ON {prefix}_items(project_id);",
                "CREATE INDEX idx_chat_project ON chat_history(project_id, created_at);",
                "CREATE INDEX idx_projects_user ON projects(user_id, updated_at);"
            ],
            "sql_script": f"-- Database DDL Script for {name}\n-- Generated by DevForge AI Database Designer\n\nPRAGMA foreign_keys = ON;\nPRAGMA journal_mode = WAL;\n\nCREATE TABLE IF NOT EXISTS users (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  email TEXT UNIQUE NOT NULL,\n  password_hash TEXT NOT NULL,\n  full_name TEXT NOT NULL,\n  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n);\n\nCREATE TABLE IF NOT EXISTS projects (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  user_id INTEGER NOT NULL,\n  name TEXT NOT NULL,\n  description TEXT,\n  budget TEXT,\n  timeline TEXT,\n  target_users TEXT,\n  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE\n);\n\nCREATE TABLE IF NOT EXISTS {prefix}_items (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  project_id INTEGER NOT NULL,\n  title TEXT NOT NULL,\n  status TEXT DEFAULT 'todo' CHECK(status IN ('todo','in_progress','done')),\n  priority TEXT DEFAULT 'medium',\n  details TEXT,\n  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n  FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE\n);\n\nCREATE TABLE IF NOT EXISTS chat_history (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  project_id INTEGER NOT NULL,\n  user_id INTEGER NOT NULL,\n  role TEXT NOT NULL CHECK(role IN ('user','assistant')),\n  message TEXT NOT NULL,\n  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n  FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE\n);\n\n-- Indexes for performance\nCREATE INDEX IF NOT EXISTS idx_users_email ON users(email);\nCREATE INDEX IF NOT EXISTS idx_items_project ON {prefix}_items(project_id);\nCREATE INDEX IF NOT EXISTS idx_chat_project ON chat_history(project_id, created_at);"
        }
    elif agent_type == "api":
        prefix = name.lower().replace(" ", "_")
        return {
            "endpoints": [
                {
                    "path": "/api/auth/register",
                    "method": "POST",
                    "description": "Registers a new user and hashes password with bcrypt.",
                    "request_body": '{\n  "email": "user@example.com",\n  "password": "strongPassword123",\n  "full_name": "John Doe"\n}',
                    "response": '{\n  "id": 1,\n  "email": "user@example.com",\n  "full_name": "John Doe",\n  "created_at": "2026-07-04T00:00:00"\n}'
                },
                {
                    "path": "/api/auth/login",
                    "method": "POST",
                    "description": "Validates user credentials and issues a JWT token.",
                    "request_body": '{\n  "email": "user@example.com",\n  "password": "strongPassword123"\n}',
                    "response": '{\n  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",\n  "token_type": "bearer",\n  "user": {"id": 1, "email": "user@example.com"}\n}'
                },
                {
                    "path": "/api/projects",
                    "method": "GET",
                    "description": "Lists all projects for the authenticated user.",
                    "request_body": "None (JWT Auth Header required)",
                    "response": '[{\n  "id": 1,\n  "name": "My Project",\n  "description": "...",\n  "created_at": "2026-07-04"\n}]'
                },
                {
                    "path": "/api/projects/{id}/chat",
                    "method": "POST",
                    "description": "Sends a message to the project AI assistant and receives a response.",
                    "request_body": '{\n  "message": "How should I structure the database?"\n}',
                    "response": '{\n  "user_message": {"role": "user", "message": "..."},\n  "assistant_message": {"role": "assistant", "message": "..."}\n}'
                },
                {
                    "path": "/api/projects/{id}/health",
                    "method": "GET",
                    "description": "Returns a comprehensive health score for the project.",
                    "request_body": "None (JWT Auth Header required)",
                    "response": '{\n  "overall_score": 72.5,\n  "grade": "B",\n  "categories": [{"category": "Security", "score": 8, "max_score": 10}]\n}'
                },
                {
                    "path": "/api/projects/{id}/improvements",
                    "method": "GET",
                    "description": "Returns AI-generated improvement suggestions for the project.",
                    "request_body": "None (JWT Auth Header required)",
                    "response": '{\n  "suggestions": [{"category": "Security", "priority": "high", "title": "..."}]\n}'
                }
            ],
            "error_handling": [
                {"code": 400, "message": "Bad Request - Input validation constraint violated."},
                {"code": 401, "message": "Unauthorized - Missing or expired Bearer Token."},
                {"code": 404, "message": "Not Found - Requested item or project does not exist."},
                {"code": 422, "message": "Unprocessable Entity - Request body schema validation failed."},
                {"code": 500, "message": "Internal Server Error - Unexpected system error."}
            ]
        }
    elif agent_type == "ui":
        return {
            "screens": [
                {
                    "name": "Splash & Login Portal",
                    "description": "Minimal login layout with glassmorphic cards and dynamic entry validation.",
                    "components": ["Form Inputs", "Forgot password route link", "Glowing brand emblem logo"],
                    "navigation": ["Navigate to Register", "Navigate to Dashboard on authenticated validation"]
                },
                {
                    "name": "Interactive Dashboard Screen",
                    "description": "SaaS-style interface showing recent projects, health scores, and project creation.",
                    "components": ["Sidebar navigation", "Stats cards grid", "Project cards", "Quick action button"],
                    "navigation": ["Navigate to Project view", "Open Creation modal", "Navigate to Settings"]
                },
                {
                    "name": "AI Report Studio",
                    "description": "Central workstation showing generated AI plans with export functionality.",
                    "components": ["Agent selection sidebar", "Report content area", "Regenerate button", "Export dropdown"],
                    "navigation": ["Return to Dashboard", "Open Export dialog"]
                },
                {
                    "name": "DevForge Chat",
                    "description": "Project-aware AI chat interface with message history and typing indicators.",
                    "components": ["Message bubbles", "Text input", "Send button", "Chat history list"],
                    "navigation": ["Return to Project", "Clear Chat button"]
                }
            ],
            "palette": {
                "primary": "#3B82F6",
                "secondary": "#10B981",
                "background": "#0D0E12",
                "accent": "#6366F1"
            },
            "typography": [
                "Brand Header: Outfit Semibold - Size 28",
                "View Headers: Inter Bold - Size 20",
                "Content Body Text: Inter Regular - Size 14",
                "Metadata captions: Inter Medium - Size 11"
            ]
        }
    elif agent_type == "test":
        prefix = name.lower().replace(" ", "_")
        return {
            "unit_tests": [
                "Test user registration input validity checks (valid email strings and password patterns).",
                f"Test Project model creation ensures budget limits ({budget}) are saved as strings.",
                "Test JWT creation validates payload encryption and expiry calculations.",
                "Test password hashing with bcrypt returns different hashes for same input.",
                "Test chat message model correctly sets role to 'user' or 'assistant'."
            ],
            "integration_tests": [
                "Verify calling API register followed immediately by login succeeds with correct status code.",
                f"Verify posting a new project item updates SQLite records correctly.",
                "Verify deleting a project correctly cascade-deletes related reports and chat history.",
                "Verify AI generation endpoint returns properly structured JSON for all agent types.",
                "Verify chat endpoint saves messages to database and returns valid response."
            ],
            "edge_cases": [
                "Test system resistance when entering extremely long names (>1000 characters).",
                "Validate system behavior when Gemini API returns corrupted JSON output.",
                "Test concurrent writes to SQLite database without locking errors.",
                "Verify token expiry handling redirects user to login page gracefully.",
                "Test project deletion when AI reports and chat history exist."
            ],
            "performance": [
                "Simulate 50 parallel client API logins within 2 seconds using FastAPI TestClient.",
                "Verify database lockouts do not occur during parallel writes (WAL mode).",
                f"Test AI generation completes within 45-second timeout under normal conditions.",
                "Verify Flutter app loads dashboard in under 3 seconds on first render."
            ]
        }
    elif agent_type == "docs":
        return {
            "readme": f"# {name}\n\n> AI Software Development Companion - Generated by DevForge AI\n\n## Overview\n{desc}\n\n## Tech Stack\n- **Frontend**: Flutter (Dart) / Material 3 / Provider\n- **Backend**: FastAPI (Python 3.10+) / Uvicorn\n- **Database**: SQLite with WAL mode\n- **AI**: Google Gemini 1.5 Flash\n\n## Quick Start\n```bash\n# Backend\ncd backend\npip install -r requirements.txt\nuvicorn app.main:app --reload --port 8000\n\n# Frontend (new terminal)\ncd frontend\nflutter pub get\nflutter run -d windows\n```\n\n## Target Users\n{desc[:200]}",
            "install_guide": f"### Setting up {name}\n\n#### Prerequisites\n- Python 3.10+\n- Flutter SDK 3.0+\n- Git\n\n#### Installation Steps\n1. Clone the repository:\n   ```bash\n   git clone https://github.com/your-org/{name.lower().replace(' ', '-')}.git\n   cd {name.lower().replace(' ', '-')}\n   ```\n2. Set up backend:\n   ```bash\n   cd backend\n   python -m venv venv\n   venv\\\\Scripts\\\\activate  # Windows\n   pip install -r requirements.txt\n   ```\n3. Configure environment variables:\n   ```bash\n   set GEMINI_API_KEY=your_api_key_here\n   set JWT_SECRET_KEY=your_secret_key_here\n   ```\n4. Start backend server:\n   ```bash\n   uvicorn app.main:app --port 8000 --reload\n   ```\n5. Run Flutter app:\n   ```bash\n   cd ../frontend\n   flutter pub get\n   flutter run -d windows\n   ```",
            "deployment": "### Deployment Instructions\n\n#### Docker Deployment\n```bash\n# Build and run with Docker Compose\ndocker-compose up --build -d\n```\n\n#### Manual Deployment\n1. Set production environment variables\n2. Run with production ASGI server:\n   ```bash\n   uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4\n   ```\n3. Configure Nginx reverse proxy\n4. Set up SSL with Let's Encrypt\n5. Configure systemd service for auto-restart"
        }
    elif agent_type == "risk":
        return {
            "risks": [
                {
                    "category": "Technical",
                    "risk": f"Completing integration tasks in Flutter/FastAPI under the {timeline} timeline may be challenging.",
                    "mitigation": "Establish a strict MVVM pattern early, write clean boilerplate templates, and use realistic simulated test rigs. Prioritize core features for MVP."
                },
                {
                    "category": "Budget",
                    "risk": f"Project operations exceeding the current {budget} constraints due to AI API costs.",
                    "mitigation": "Host backend on SQLite to minimize hosting costs. Use Gemini demo mode during development. Deploy on free tier Render/Railway for initial launch."
                },
                {
                    "category": "Security",
                    "risk": "Weak user authorization models leading to unauthorized project access.",
                    "mitigation": "Enforce JWT authorization tokens for every API endpoint. Implement input validation with Pydantic. Add rate limiting to authentication endpoints."
                },
                {
                    "category": "Performance",
                    "risk": "SQLite write locks under concurrent users causing 503 errors.",
                    "mitigation": "Enable WAL mode (PRAGMA journal_mode=WAL). Implement connection pooling. Consider PostgreSQL migration at 100+ concurrent users."
                },
                {
                    "category": "Reliability",
                    "risk": "Gemini API unavailability causing AI features to fail completely.",
                    "mitigation": "Demo mode fallback already implemented. Cache successful AI responses. Display graceful error messages to users during outages."
                }
            ]
        }
    elif agent_type == "tasks":
        return {
            "milestones": [
                "Milestone 1: Core backend and database schemas established",
                "Milestone 2: Authentication workflow integrated in Flutter",
                "Milestone 3: All AI agents functional with demo mode",
                "Milestone 4: Chat, Progress, and Health features complete",
                "Milestone 5: Production build validated and GitHub-ready"
            ],
            "sprint_plan": [
                {
                    "sprint": "Sprint 1: Foundation & Database",
                    "duration": 2,
                    "tasks": [
                        "Create SQLite database schemas",
                        "Design REST authentication logic",
                        "Setup Flutter skeleton layout & Providers"
                    ]
                },
                {
                    "sprint": "Sprint 2: Core Features",
                    "duration": 2,
                    "tasks": [
                        "Build project management endpoints",
                        "Design dashboard glassmorphism cards",
                        "Implement AI agent generation flow"
                    ]
                },
                {
                    "sprint": "Sprint 3: Advanced Features",
                    "duration": 2,
                    "tasks": [
                        "Build DevForge Chat interface",
                        "Implement Progress Tracker",
                        "Build Health Analyzer and Improvements screens"
                    ]
                },
                {
                    "sprint": "Sprint 4: Polish & Deploy",
                    "duration": 1,
                    "tasks": [
                        "Performance optimization",
                        "Bug fixes and edge case handling",
                        "Write unit and integration tests"
                    ]
                }
            ],
            "kanban": {
                "todo": [
                    "Format exports engine to render PDF",
                    "Verify light theme readability contrast ratios",
                    "Add push notification support"
                ],
                "in_progress": [
                    "Design interactive Kanban UI widget",
                    "Implement health score visualization"
                ],
                "done": [
                    "Set up initial workspace directory structures",
                    "Create config.py settings schema",
                    "Implement JWT authentication",
                    "Build project CRUD operations",
                    "Implement 9 AI agents with demo mode"
                ]
            }
        }

    return {"message": "Generic project report."}
