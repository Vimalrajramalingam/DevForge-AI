from fastapi import APIRouter, Depends, HTTPException, status, Response
from app.database import get_db_conn
from app.schemas import (
    UserResponse, AIGenerationResponse, ReportResponse,
    ProgressStageUpdate, ProjectProgressResponse, ProgressStageResponse,
    HealthReportResponse, HealthCategoryScore,
    ImprovementsResponse, ImprovementSuggestion
)
from app.auth import get_current_user
from app.services.gemini import generate_report, generate_improvements
import sqlite3
import json
from datetime import datetime

router = APIRouter(prefix="/api/projects", tags=["ai"])

VALID_AGENTS = [
    "requirements",
    "architecture",
    "database",
    "api",
    "ui",
    "test",
    "docs",
    "risk",
    "tasks"
]

SDLC_STAGES = [
    "idea",
    "requirements",
    "architecture",
    "database",
    "api",
    "development",
    "testing",
    "deployment"
]

@router.post("/{project_id}/generate/{agent_type}", response_model=AIGenerationResponse)
def run_ai_agent(
    project_id: int,
    agent_type: str,
    current_user: UserResponse = Depends(get_current_user)
):
    if agent_type not in VALID_AGENTS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid agent type. Must be one of: {', '.join(VALID_AGENTS)}"
        )

    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, name, description, target_users, budget, timeline FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        project_row = cursor.fetchone()
        if not project_row:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
        project_dict = dict(project_row)

    try:
        result_content = generate_report(project_dict, agent_type)
        content_json = json.dumps(result_content)

        with get_db_conn() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO reports (project_id, agent_type, content)
                VALUES (?, ?, ?)
                ON CONFLICT(project_id, agent_type)
                DO UPDATE SET content=excluded.content, created_at=CURRENT_TIMESTAMP
                """,
                (project_id, agent_type, content_json)
            )
            cursor.execute(
                "UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                (project_id,)
            )

            # Auto-mark corresponding SDLC stage as completed
            stage_map = {
                "requirements": "requirements",
                "architecture": "architecture",
                "database": "database",
                "api": "api",
            }
            if agent_type in stage_map:
                stage = stage_map[agent_type]
                cursor.execute(
                    """INSERT INTO project_progress (project_id, user_id, stage, completed)
                       VALUES (?, ?, ?, 1)
                       ON CONFLICT(project_id, stage)
                       DO UPDATE SET completed=1, updated_at=CURRENT_TIMESTAMP""",
                    (project_id, current_user.id, stage)
                )
                # Also mark idea stage if not already done
                cursor.execute(
                    """INSERT INTO project_progress (project_id, user_id, stage, completed)
                       VALUES (?, ?, 'idea', 1)
                       ON CONFLICT(project_id, stage)
                       DO UPDATE SET completed=1, updated_at=CURRENT_TIMESTAMP""",
                    (project_id, current_user.id)
                )

        return AIGenerationResponse(agent_type=agent_type, content=result_content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Generation failed: {str(e)}"
        )

@router.get("/{project_id}/reports", response_model=list[ReportResponse])
def get_project_reports(
    project_id: int,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        cursor.execute(
            "SELECT id, project_id, agent_type, content, created_at FROM reports WHERE project_id = ?",
            (project_id,)
        )
        rows = cursor.fetchall()

        return [
            ReportResponse(
                id=row["id"],
                project_id=row["project_id"],
                agent_type=row["agent_type"],
                content=row["content"],
                created_at=str(row["created_at"])
            )
            for row in rows
        ]

@router.get("/{project_id}/progress", response_model=ProjectProgressResponse)
def get_project_progress(
    project_id: int,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        # Get stored progress
        cursor.execute(
            """SELECT stage, completed, notes, updated_at
               FROM project_progress
               WHERE project_id = ? AND user_id = ?""",
            (project_id, current_user.id)
        )
        progress_rows = {row["stage"]: row for row in cursor.fetchall()}

        # Get available reports to auto-calculate stages
        cursor.execute(
            "SELECT agent_type FROM reports WHERE project_id = ?",
            (project_id,)
        )
        report_types = {row["agent_type"] for row in cursor.fetchall()}

    # Build stages list
    stages = []
    completed_count = 0

    stage_completion_map = {
        "idea": True,  # Always completed once a project exists
        "requirements": "requirements" in report_types,
        "architecture": "architecture" in report_types,
        "database": "database" in report_types,
        "api": "api" in report_types,
        "development": False,
        "testing": "test" in report_types,
        "deployment": False,
    }

    for stage in SDLC_STAGES:
        # Check DB override first, then auto-calculate
        db_entry = progress_rows.get(stage)
        if db_entry:
            is_completed = bool(db_entry["completed"])
        else:
            is_completed = stage_completion_map.get(stage, False)

        if is_completed:
            completed_count += 1

        stages.append(ProgressStageResponse(
            stage=stage,
            completed=is_completed,
            notes=db_entry["notes"] if db_entry else None,
            updated_at=str(db_entry["updated_at"]) if db_entry else datetime.now().isoformat()
        ))

    total = len(SDLC_STAGES)
    percentage = (completed_count / total) * 100

    # Determine current stage (first incomplete)
    current_stage = None
    next_step = None
    stage_next_steps = {
        "idea": "Run Requirements Analyzer to define project scope",
        "requirements": "Run Architecture Generator to design system structure",
        "architecture": "Run Database Designer to create data models",
        "database": "Run API Generator to define REST endpoints",
        "api": "Begin development phase and code implementation",
        "development": "Run Test Case Generator and perform quality assurance",
        "testing": "Prepare deployment infrastructure and CI/CD pipelines",
        "deployment": "Project successfully deployed! Monitor and iterate."
    }

    for s in stages:
        if not s.completed:
            current_stage = s.stage
            next_step = stage_next_steps.get(s.stage, "Continue with next stage")
            break

    return ProjectProgressResponse(
        project_id=project_id,
        stages=stages,
        completion_percentage=round(percentage, 1),
        completed_count=completed_count,
        total_stages=total,
        current_stage=current_stage,
        next_recommended_step=next_step
    )

@router.put("/{project_id}/progress", response_model=ProjectProgressResponse)
def update_project_progress(
    project_id: int,
    stage_update: ProgressStageUpdate,
    current_user: UserResponse = Depends(get_current_user)
):
    if stage_update.stage not in SDLC_STAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid stage. Must be one of: {', '.join(SDLC_STAGES)}"
        )

    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Project not found")

        cursor.execute(
            """INSERT INTO project_progress (project_id, user_id, stage, completed, notes)
               VALUES (?, ?, ?, ?, ?)
               ON CONFLICT(project_id, stage)
               DO UPDATE SET completed=excluded.completed, notes=excluded.notes,
                             updated_at=CURRENT_TIMESTAMP""",
            (project_id, current_user.id, stage_update.stage,
             1 if stage_update.completed else 0, stage_update.notes)
        )

    return get_project_progress(project_id, current_user)

@router.get("/{project_id}/health", response_model=HealthReportResponse)
def get_project_health(
    project_id: int,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, name, description FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        project_row = cursor.fetchone()
        if not project_row:
            raise HTTPException(status_code=404, detail="Project not found")

        cursor.execute(
            "SELECT agent_type FROM reports WHERE project_id = ?",
            (project_id,)
        )
        report_types = {row["agent_type"] for row in cursor.fetchall()}

        cursor.execute(
            "SELECT COUNT(*) as cnt FROM chat_history WHERE project_id = ?",
            (project_id,)
        )
        chat_count = cursor.fetchone()["cnt"]

    # Calculate health scores based on what's been generated
    categories = []

    def make_score(name: str, earned: float, max_s: float, desc: str) -> HealthCategoryScore:
        pct = (earned / max_s) * 100
        color = "green" if pct >= 70 else ("yellow" if pct >= 40 else "red")
        return HealthCategoryScore(
            category=name,
            score=earned,
            max_score=max_s,
            description=desc,
            color=color
        )

    req_score = 10.0 if "requirements" in report_types else 0.0
    categories.append(make_score(
        "Requirements",
        req_score, 10.0,
        "Requirements document generated and project goals defined" if req_score > 0 else "No requirements document generated yet"
    ))

    arch_score = 10.0 if "architecture" in report_types else 0.0
    categories.append(make_score(
        "Architecture",
        arch_score, 10.0,
        "System architecture designed and tech stack defined" if arch_score > 0 else "Architecture not yet defined"
    ))

    db_score = 10.0 if "database" in report_types else 0.0
    categories.append(make_score(
        "Database Design",
        db_score, 10.0,
        "Database schema and ER diagram generated" if db_score > 0 else "Database design not completed"
    ))

    api_score = 10.0 if "api" in report_types else 0.0
    categories.append(make_score(
        "API Design",
        api_score, 10.0,
        "REST API endpoints defined and documented" if api_score > 0 else "API endpoints not yet defined"
    ))

    docs_score = 0.0
    if "docs" in report_types:
        docs_score += 7.0
    if "risk" in report_types:
        docs_score += 3.0
    categories.append(make_score(
        "Documentation",
        docs_score, 10.0,
        f"Documentation coverage: {docs_score * 10:.0f}%"
    ))

    sec_score = 5.0  # Base security score (JWT auth used)
    if "risk" in report_types:
        sec_score += 5.0
    categories.append(make_score(
        "Security",
        sec_score, 10.0,
        "JWT authentication active" + ("; Risk analysis performed" if sec_score > 5 else "; Run Risk Analyzer for full assessment")
    ))

    test_score = 0.0
    if "test" in report_types:
        test_score += 8.0
    if chat_count > 5:
        test_score = min(test_score + 2.0, 10.0)
    categories.append(make_score(
        "Testing",
        test_score, 10.0,
        "Test cases generated" if test_score >= 8 else "Run Test Case Generator to improve this score"
    ))

    total_score = sum(c.score for c in categories)
    total_max = sum(c.max_score for c in categories)
    overall_pct = (total_score / total_max) * 100

    if overall_pct >= 90:
        grade = "A+"
    elif overall_pct >= 80:
        grade = "A"
    elif overall_pct >= 70:
        grade = "B"
    elif overall_pct >= 60:
        grade = "C"
    elif overall_pct >= 50:
        grade = "D"
    else:
        grade = "F"

    summary = (
        f"Your project '{project_row['name']}' has an overall health score of {overall_pct:.1f}%. "
        f"{'Excellent work! The project is well-documented and structured.' if overall_pct >= 80 else 'Generate more AI reports to improve your project health score.'}"
    )

    return HealthReportResponse(
        project_id=project_id,
        overall_score=round(overall_pct, 1),
        grade=grade,
        categories=categories,
        summary=summary,
        generated_at=datetime.now().isoformat()
    )

@router.get("/{project_id}/improvements", response_model=ImprovementsResponse)
def get_project_improvements(
    project_id: int,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, name, description, target_users, budget, timeline FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        project_row = cursor.fetchone()
        if not project_row:
            raise HTTPException(status_code=404, detail="Project not found")

        project_dict = dict(project_row)

        cursor.execute(
            "SELECT agent_type FROM reports WHERE project_id = ?",
            (project_id,)
        )
        report_types = {row["agent_type"] for row in cursor.fetchall()}

    suggestions = generate_improvements(project_dict, list(report_types))

    return ImprovementsResponse(
        project_id=project_id,
        suggestions=suggestions,
        generated_at=datetime.now().isoformat()
    )
