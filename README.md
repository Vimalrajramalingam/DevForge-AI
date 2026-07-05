# DevForge AI - AI Software Project Manager

DevForge AI is an AI-powered software planning application that enables developers and project managers to transform a simple software concept into a comprehensive, production-ready development plan. 

The application utilizes multiple specialized **AI Agents** that analyze the project's parameters and produce structural blueprints, database scripts, API routes, user sequence trees, test cases, and sprint boards.

---

## Technical Stack

*   **Backend**: Python FastAPI, Uvicorn, SQLite Database (native `sqlite3`), JWT Authentication, and Gemini 1.5 REST interface.
*   **Frontend**: Flutter (Material 3), Provider state management, responsive grid layouts, and glassmorphic UI elements.
*   **AI Engine**: Google Gemini API (Simulated Fallback Engine when API key is unconfigured).

---

## Directory Structure

```text
/DevForge-ai
├── backend/                  # FastAPI Application
│   ├── app/
│   │   ├── main.py           # Server Entry & CORS Config
│   │   ├── config.py         # Key & File Configuration
│   │   ├── database.py       # sqlite3 Connection & Migrations
│   │   ├── auth.py           # bcrypt Hashing & JWT Verify
│   │   ├── schemas.py        # Request/Response Validation DTOs
│   │   ├── routers/
│   │   │   ├── auth.py       # Signup & Login Routes
│   │   │   ├── projects.py   # CRUD & Duplication Routes
│   │   │   └── ai.py         # AI Agent Generation Router
│   │   └── services/
│   │       └── gemini.py     # prompt configurations & API requests
│   ├── requirements.txt      # Python Dependencies
│   └── test_api.py           # Backend Automated Integration Tests
└── frontend/                 # Flutter Client Application
    ├── lib/
    │   ├── main.dart         # Provider Initialization & App Root
    │   ├── core/
    │   │   ├── theme.dart    # Obsidian Dark & Premium Light Themes
    │   │   └── api_client.dart # JWT Interceptor HTTP Helper
    │   ├── models/
    │   │   ├── user.dart     # User Profile DTO
    │   │   ├── project.dart  # Project Workspace DTO
    │   │   └── report.dart   # AI Agent Report DTO
    │   ├── providers/
    │   │   ├── auth_provider.dart # Auth state manager
    │   │   ├── project_provider.dart # Workspace CRUD & Generation loader
    │   │   └── theme_provider.dart # Dark/Light Preference cache
    │   ├── widgets/
    │   │   ├── glass_card.dart     # BackdropFilter Blur Container
    │   │   └── sidebar.dart        # Responsive SideBar/BottomNav Wrapper
    │   └── screens/
    │       ├── splash_screen.dart  # Session check loader
    │       ├── login_screen.dart   # Interactive email login
    │       ├── register_screen.dart # Sign up validations
    │       ├── forgot_password_screen.dart # Password reset simulator
    │       ├── dashboard_screen.dart # Stats grid & Workspace creator
    │       ├── project_detail_screen.dart # Agent studio hub (with Kanban & Palette widgets)
    │       ├── history_screen.dart # Realtime search list with actions
    │       ├── settings_screen.dart # Switch themes, languages, & configure Gemini Key
    │       ├── profile_screen.dart # User credentials edit portal
    │       └── about_screen.dart   # Agent details overview
    └── pubspec.yaml          # Flutter Client configuration dependencies
```

---

## Getting Started

### Prerequisites
*   Python 3.10+
*   Flutter SDK (3.22+)
*   Gemini API Key (Optional; fallback simulation mode is active by default)

---

### 1. Setup and Run Backend Server

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```

2.  Create a virtual environment and activate it:
    ```bash
    python -m venv venv
    # On Windows:
    venv\Scripts\activate
    ```

3.  Install dependencies:
    ```bash
    pip install fastapi uvicorn pydantic pydantic-settings pyjwt passlib bcrypt python-multipart httpx email-validator
    ```

4.  Set up environment variable (optional, for real Gemini API integration):
    ```bash
    # On Windows PowerShell:
    $env:GEMINI_API_KEY="your-gemini-api-key-here"
    ```

5.  Start the development server:
    ```bash
    uvicorn app.main:app --port 8000 --reload
    ```
    *   The server will start at `http://localhost:8000`
    *   API docs are available at `http://localhost:8000/docs`

6.  (Optional) Run the automated integration test suite:
    ```bash
    python test_api.py
    ```

---

### 2. Setup and Run Flutter Frontend

1.  Navigate to the frontend directory:
    ```bash
    cd frontend
    ```

2.  Fetch packages:
    ```bash
    flutter pub get
    ```

3.  Configure server address (if running backend on a different port/IP):
    *   Launch the app, navigate to **Settings**, and update the **API Base URL** text field (defaults to `http://localhost:8000`).

4.  Compile and run the client:
    ```bash
    # Run in Chrome browser (Web)
    flutter run -d chrome
    
    # Run on Windows Desktop
    flutter run -d windows
    ```

---

## Specialized AI Agents Architecture

DevForge AI launches **9 distinct virtual roles** to planning workflows:
1.  **Requirements Analyzer**: Identifies functional limits, product goals, business objective parameters, and system scale constraints.
2.  **Architecture Designer**: Formulates directory hierarchies, suggests system tech stacks, and designs data pipeline workflows.
3.  **Database Architect**: Normalizes structures, creates ER diagrams, and generates standard SQL DDL scripts.
4.  **REST API Generator**: Outlines API paths (GET/POST/PUT/DELETE), request schemas, reply payloads, and error codes.
5.  **UI Planner**: Dictates color palette swatches, typography tokens, screen components, and navigation structures.
6.  **Test Case Generator**: Formulates unit tests, integration paths, performance benchmarks, and edge cases.
7.  **Documentation Generator**: Configures setup readmes, deploy guidelines, and technical details.
8.  **Risk Analyzer**: Evaluates budget timeline bottlenecks and security risk mitigations.
9.  **Task Planner**: Schedules sprint timelines and builds an interactive **Kanban Board** to track task status transitions.

---

## License
MIT License. Created as a production-grade demonstration for AI-Assisted software architecture development.
