from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
import time

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    success: bool
    message: str
    token: str | None = None


FAKE_USERS = {
    "admin": "admin123",
    "user": "password123",
}


@router.post("/login", response_model=LoginResponse)
def login(credentials: LoginRequest):
    if not credentials.username or not credentials.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username and password are required",
        )

    if credentials.username not in FAKE_USERS:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if FAKE_USERS[credentials.username] != credentials.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    fake_token = f"token_{credentials.username}_{int(time.time())}"
    return LoginResponse(
        success=True,
        message="Login successful",
        token=fake_token,
    )
