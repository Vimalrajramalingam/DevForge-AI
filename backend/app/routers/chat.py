from fastapi import APIRouter, Depends, HTTPException, status
from app.database import get_db_conn
from app.schemas import (
    UserResponse, ChatMessageCreate, ChatMessageResponse, ChatResponse
)
from app.auth import get_current_user
from app.services.gemini import generate_chat_response
import sqlite3

router = APIRouter(prefix="/api/projects", tags=["chat"])

@router.post("/{project_id}/chat", response_model=ChatResponse)
def send_chat_message(
    project_id: int,
    message_in: ChatMessageCreate,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()

        # Verify project ownership
        cursor.execute(
            "SELECT id, name, description, target_users, budget, timeline FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        project_row = cursor.fetchone()
        if not project_row:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        project_dict = dict(project_row)

        # Get existing chat history for context (last 10 messages)
        cursor.execute(
            """SELECT role, message FROM chat_history
               WHERE project_id = ? AND user_id = ?
               ORDER BY created_at DESC LIMIT 10""",
            (project_id, current_user.id)
        )
        history_rows = cursor.fetchall()
        # Reverse to get chronological order
        chat_history = [{"role": row["role"], "message": row["message"]} for row in reversed(history_rows)]

        # Get existing reports for context
        cursor.execute(
            "SELECT agent_type, content FROM reports WHERE project_id = ?",
            (project_id,)
        )
        reports_rows = cursor.fetchall()
        available_reports = [row["agent_type"] for row in reports_rows]

    # Save user message
    with get_db_conn() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO chat_history (project_id, user_id, role, message) VALUES (?, ?, ?, ?)",
                (project_id, current_user.id, "user", message_in.message)
            )
            user_msg_id = cursor.lastrowid
            cursor.execute(
                "SELECT id, project_id, role, message, created_at FROM chat_history WHERE id = ?",
                (user_msg_id,)
            )
            user_row = cursor.fetchone()
        except sqlite3.Error as e:
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    user_message_resp = ChatMessageResponse(
        id=user_row["id"],
        project_id=user_row["project_id"],
        role=user_row["role"],
        message=user_row["message"],
        created_at=str(user_row["created_at"])
    )

    # Generate AI response
    try:
        ai_response_text = generate_chat_response(
            project=project_dict,
            user_message=message_in.message,
            chat_history=chat_history,
            available_reports=available_reports
        )
    except Exception as e:
        ai_response_text = f"I'm currently having trouble processing your request. Please try again. (Error: {str(e)[:100]})"

    # Save assistant message
    with get_db_conn() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO chat_history (project_id, user_id, role, message) VALUES (?, ?, ?, ?)",
                (project_id, current_user.id, "assistant", ai_response_text)
            )
            assistant_msg_id = cursor.lastrowid
            cursor.execute(
                "SELECT id, project_id, role, message, created_at FROM chat_history WHERE id = ?",
                (assistant_msg_id,)
            )
            assistant_row = cursor.fetchone()
        except sqlite3.Error as e:
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    assistant_message_resp = ChatMessageResponse(
        id=assistant_row["id"],
        project_id=assistant_row["project_id"],
        role=assistant_row["role"],
        message=assistant_row["message"],
        created_at=str(assistant_row["created_at"])
    )

    return ChatResponse(
        user_message=user_message_resp,
        assistant_message=assistant_message_resp
    )

@router.get("/{project_id}/chat", response_model=list[ChatMessageResponse])
def get_chat_history(
    project_id: int,
    current_user: UserResponse = Depends(get_current_user)
):
    with get_db_conn() as conn:
        cursor = conn.cursor()

        # Verify project ownership
        cursor.execute(
            "SELECT id FROM projects WHERE id = ? AND user_id = ?",
            (project_id, current_user.id)
        )
        if not cursor.fetchone():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

        cursor.execute(
            """SELECT id, project_id, role, message, created_at
               FROM chat_history
               WHERE project_id = ? AND user_id = ?
               ORDER BY created_at ASC""",
            (project_id, current_user.id)
        )
        rows = cursor.fetchall()

        return [
            ChatMessageResponse(
                id=row["id"],
                project_id=row["project_id"],
                role=row["role"],
                message=row["message"],
                created_at=str(row["created_at"])
            )
            for row in rows
        ]

@router.delete("/{project_id}/chat")
def clear_chat_history(
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
            "DELETE FROM chat_history WHERE project_id = ? AND user_id = ?",
            (project_id, current_user.id)
        )

    return {"message": "Chat history cleared successfully"}
