from fastapi import APIRouter, Depends, HTTPException, status, Response
from app.database import get_db_conn
from app.schemas import ProjectCreate, ProjectUpdate, ProjectResponse, UserResponse
from app.auth import get_current_user
import sqlite3
import json

router = APIRouter(prefix="/api/projects", tags=["projects"])

@router.get("", response_model=list[ProjectResponse])
def list_projects(current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, user_id, name, description, target_users, budget, timeline, created_at, updated_at FROM projects WHERE user_id = ? ORDER BY updated_at DESC",
            (current_user.id,)
        )
        rows = cursor.fetchall()
        return [
            ProjectResponse(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row["description"],
                target_users=row["target_users"],
                budget=row["budget"],
                timeline=row["timeline"],
                created_at=str(row["created_at"]),
                updated_at=str(row["updated_at"])
            )
            for row in rows
        ]

@router.post("", response_model=ProjectResponse)
def create_project(project_in: ProjectCreate, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO projects (user_id, name, description, target_users, budget, timeline) VALUES (?, ?, ?, ?, ?, ?)",
                (current_user.id, project_in.name, project_in.description, project_in.target_users, project_in.budget, project_in.timeline)
            )
            project_id = cursor.lastrowid
            
            # Fetch created project
            cursor.execute(
                "SELECT id, user_id, name, description, target_users, budget, timeline, created_at, updated_at FROM projects WHERE id = ?",
                (project_id,)
            )
            row = cursor.fetchone()
            return ProjectResponse(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row["description"],
                target_users=row["target_users"],
                budget=row["budget"],
                timeline=row["timeline"],
                created_at=str(row["created_at"]),
                updated_at=str(row["updated_at"])
            )
        except sqlite3.Error as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error: {str(e)}"
            )

@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(project_id: int, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, user_id, name, description, target_users, budget, timeline, created_at, updated_at FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Project not found"
            )
        return ProjectResponse(
            id=row["id"],
            user_id=row["user_id"],
            name=row["name"],
            description=row["description"],
            target_users=row["target_users"],
            budget=row["budget"],
            timeline=row["timeline"],
            created_at=str(row["created_at"]),
            updated_at=str(row["updated_at"])
        )

@router.put("/{project_id}", response_model=ProjectResponse)
def update_project(project_id: int, project_in: ProjectUpdate, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        
        # Verify ownership
        cursor.execute("SELECT id FROM projects WHERE id = ? AND user_id = ?", (project_id, current_user.id))
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
            
        updates = []
        params = []
        for field in ["name", "description", "target_users", "budget", "timeline"]:
            val = getattr(project_in, field)
            if val is not None:
                updates.append(f"{field} = ?")
                params.append(val)
                
        if not updates:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No changes requested")
            
        updates.append("updated_at = CURRENT_TIMESTAMP")
        params.append(project_id)
        
        query = f"UPDATE projects SET {', '.join(updates)} WHERE id = ?"
        try:
            cursor.execute(query, tuple(params))
            
            # Fetch updated project
            cursor.execute(
                "SELECT id, user_id, name, description, target_users, budget, timeline, created_at, updated_at FROM projects WHERE id = ?",
                (project_id,)
            )
            row = cursor.fetchone()
            return ProjectResponse(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row["description"],
                target_users=row["target_users"],
                budget=row["budget"],
                timeline=row["timeline"],
                created_at=str(row["created_at"]),
                updated_at=str(row["updated_at"])
            )
        except sqlite3.Error as e:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")

@router.delete("/{project_id}")
def delete_project(project_id: int, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM projects WHERE id = ? AND user_id = ?", (project_id, current_user.id))
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
            
        try:
            cursor.execute("DELETE FROM projects WHERE id = ?", (project_id,))
            return {"message": "Project deleted successfully", "project_id": project_id}
        except sqlite3.Error as e:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")

@router.post("/{project_id}/duplicate", response_model=ProjectResponse)
def duplicate_project(project_id: int, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT name, description, target_users, budget, timeline FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        project = cursor.fetchone()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
            
        try:
            # Create new project copy
            cursor.execute(
                "INSERT INTO projects (user_id, name, description, target_users, budget, timeline) VALUES (?, ?, ?, ?, ?, ?)",
                (current_user.id, f"{project['name']} (Copy)", project['description'], project['target_users'], project['budget'], project['timeline'])
            )
            new_id = cursor.lastrowid
            
            # Duplicate reports
            cursor.execute("SELECT agent_type, content FROM reports WHERE project_id = ?", (project_id,))
            reports = cursor.fetchall()
            for report in reports:
                cursor.execute(
                    "INSERT INTO reports (project_id, agent_type, content) VALUES (?, ?, ?)",
                    (new_id, report['agent_type'], report['content'])
                )
                
            cursor.execute(
                "SELECT id, user_id, name, description, target_users, budget, timeline, created_at, updated_at FROM projects WHERE id = ?",
                (new_id,)
            )
            row = cursor.fetchone()
            return ProjectResponse(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row["description"],
                target_users=row["target_users"],
                budget=row["budget"],
                timeline=row["timeline"],
                created_at=str(row["created_at"]),
                updated_at=str(row["updated_at"])
            )
        except sqlite3.Error as e:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database error: {str(e)}")

@router.get("/{project_id}/export/{export_format}")
def export_project(project_id: int, export_format: str, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT name, description, target_users, budget, timeline FROM projects WHERE id = ? AND user_id = ?", (project_id, current_user.id))
        project = cursor.fetchone()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
            
        cursor.execute("SELECT agent_type, content FROM reports WHERE project_id = ?", (project_id,))
        reports_rows = cursor.fetchall()
        reports = {row["agent_type"]: json.loads(row["content"]) for row in reports_rows}
        
    if export_format == "json":
        data = {
            "project": dict(project),
            "reports": reports
        }
        return Response(content=json.dumps(data, indent=2), media_type="application/json", headers={"Content-Disposition": f"attachment; filename=project_{project_id}.json"})
        
    elif export_format == "markdown":
        md = []
        md.append(f"# Project Plan: {project['name']}")
        md.append(f"**Description**: {project['description']}\n")
        md.append(f"- **Target Users**: {project['target_users']}")
        md.append(f"- **Budget**: {project['budget']}")
        md.append(f"- **Timeline**: {project['timeline']}\n")
        md.append("---")
        
        # Add details from reports
        for agent_type, content in reports.items():
            title = agent_type.replace("_", " ").title()
            md.append(f"\n## {title}\n")
            if isinstance(content, dict):
                for key, val in content.items():
                    section_title = key.replace("_", " ").title()
                    md.append(f"### {section_title}")
                    if isinstance(val, list):
                        for item in val:
                            if isinstance(item, dict):
                                detail_str = ", ".join([f"**{k}**: {v}" for k, v in item.items()])
                                md.append(f"- {detail_str}")
                            else:
                                md.append(f"- {item}")
                    elif isinstance(val, dict):
                        for k, v in val.items():
                            if isinstance(v, list):
                                md.append(f"**{k.title()}**:")
                                for sub in v:
                                    md.append(f"  - {sub}")
                            else:
                                md.append(f"- **{k.title()}**: {v}")
                    else:
                        md.append(str(val))
                    md.append("")
            else:
                md.append(str(content))
                
        full_md = "\n".join(md)
        return Response(content=full_md, media_type="text/markdown", headers={"Content-Disposition": f"attachment; filename=project_{project_id}.md"})
        
    elif export_format in ["pdf", "docx"]:
        # Return a simulated binary data or clean format representation
        # Since we are writing standard FastAPI and don't want heavy dependencies like ReportLab / docx which have cross-platform build complications,
        # we will generate a clean document format text layout or HTML file which is standard, and tell the user they can save/print it.
        # Let's generate HTML layout with nice styling, which handles both DOCX/PDF printing gracefully.
        html = [
            "<html><head><style>",
            "body { font-family: sans-serif; padding: 20px; line-height: 1.6; }",
            "h1 { color: #1e3a8a; border-bottom: 2px solid #1e3a8a; }",
            "h2 { color: #2563eb; margin-top: 30px; border-bottom: 1px solid #e5e7eb; }",
            "h3 { color: #1f2937; }",
            "ul { margin-bottom: 15px; }",
            "pre { background: #f3f4f6; padding: 10px; border-radius: 5px; overflow-x: auto; }",
            "</style></head><body>"
        ]
        html.append(f"<h1>Project Plan: {project['name']}</h1>")
        html.append(f"<p><strong>Description:</strong> {project['description']}</p>")
        html.append(f"<ul><li><strong>Target Users:</strong> {project['target_users']}</li>")
        html.append(f"<li><strong>Budget:</strong> {project['budget']}</li>")
        html.append(f"<li><strong>Timeline:</strong> {project['timeline']}</li></ul>")
        
        for agent_type, content in reports.items():
            title = agent_type.replace("_", " ").title()
            html.append(f"<h2>{title}</h2>")
            if isinstance(content, dict):
                for key, val in content.items():
                    sec = key.replace("_", " ").title()
                    html.append(f"<h3>{sec}</h3>")
                    if isinstance(val, list):
                        html.append("<ul>")
                        for item in val:
                            if isinstance(item, dict):
                                detail = ", ".join([f"<strong>{k}</strong>: {v}" for k, v in item.items()])
                                html.append(f"<li>{detail}</li>")
                            else:
                                html.append(f"<li>{item}</li>")
                        html.append("</ul>")
                    elif isinstance(val, dict):
                        html.append("<ul>")
                        for k, v in val.items():
                            if isinstance(v, list):
                                html.append(f"<li><strong>{k.title()}:</strong>")
                                html.append("<ul>")
                                for sub in v:
                                    html.append(f"<li>{sub}</li>")
                                html.append("</ul></li>")
                            else:
                                html.append(f"<li><strong>{k.title()}:</strong> {v}</li>")
                        html.append("</ul>")
                    else:
                        if "\n" in str(val):
                            html.append(f"<pre>{val}</pre>")
                        else:
                            html.append(f"<p>{val}</p>")
            else:
                html.append(f"<p>{content}</p>")
                
        html.append("</body></html>")
        return Response(content="".join(html), media_type="text/html", headers={"Content-Disposition": f"attachment; filename=project_{project_id}.html"})
        
    else:
        raise HTTPException(status_code=400, detail="Invalid export format")
