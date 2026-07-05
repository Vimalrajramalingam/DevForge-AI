from fastapi import APIRouter, Depends, HTTPException, status
from app.database import get_db_conn
from app.schemas import UserRegister, UserLogin, UserResponse, UserUpdate, Token
from app.auth import get_password_hash, verify_password, create_access_token, get_current_user
import sqlite3

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/register", response_model=UserResponse)
def register(user_in: UserRegister):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        
        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE email = ?", (user_in.email,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
            
        hashed_password = get_password_hash(user_in.password)
        try:
            cursor.execute(
                "INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)",
                (user_in.email, hashed_password, user_in.full_name)
            )
            user_id = cursor.lastrowid
            
            # Fetch created user
            cursor.execute("SELECT id, email, full_name, created_at FROM users WHERE id = ?", (user_id,))
            user = cursor.fetchone()
            
            return UserResponse(
                id=user["id"],
                email=user["email"],
                full_name=user["full_name"],
                created_at=str(user["created_at"])
            )
        except sqlite3.Error as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error: {str(e)}"
            )

@router.post("/login", response_model=Token)
def login(credentials: UserLogin):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, email, password_hash, full_name, created_at FROM users WHERE email = ?", (credentials.email,))
        user = cursor.fetchone()
        
        if not user or not verify_password(credentials.password, user["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        access_token = create_access_token(data={"sub": str(user["id"])})
        
        user_response = UserResponse(
            id=user["id"],
            email=user["email"],
            full_name=user["full_name"],
            created_at=str(user["created_at"])
        )
        
        return Token(
            access_token=access_token,
            token_type="bearer",
            user=user_response
        )

@router.get("/me", response_model=UserResponse)
def get_me(current_user: UserResponse = Depends(get_current_user)):
    return current_user

@router.put("/update", response_model=UserResponse)
def update_profile(user_in: UserUpdate, current_user: UserResponse = Depends(get_current_user)):
    with get_db_conn() as conn:
        cursor = conn.cursor()
        
        updates = []
        params = []
        if user_in.full_name is not None:
            updates.append("full_name = ?")
            params.append(user_in.full_name)
        if user_in.password is not None:
            hashed_password = get_password_hash(user_in.password)
            updates.append("password_hash = ?")
            params.append(hashed_password)
            
        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No updates provided"
            )
            
        params.append(current_user.id)
        query = f"UPDATE users SET {', '.join(updates)} WHERE id = ?"
        
        try:
            cursor.execute(query, tuple(params))
            
            # Fetch updated user
            cursor.execute("SELECT id, email, full_name, created_at FROM users WHERE id = ?", (current_user.id,))
            user = cursor.fetchone()
            
            return UserResponse(
                id=user["id"],
                email=user["email"],
                full_name=user["full_name"],
                created_at=str(user["created_at"])
            )
        except sqlite3.Error as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error: {str(e)}"
            )
