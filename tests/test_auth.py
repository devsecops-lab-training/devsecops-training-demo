from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_login_success():
    response = client.post(
        "/auth/login",
        json={"username": "admin", "password": "admin123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Login successful"
    assert data["token"].startswith("token_admin_")


def test_login_wrong_password():
    response = client.post(
        "/auth/login",
        json={"username": "admin", "password": "wrongpassword"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


def test_login_unknown_user():
    response = client.post(
        "/auth/login",
        json={"username": "hacker", "password": "whatever"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


def test_login_empty_fields():
    response = client.post(
        "/auth/login",
        json={"username": "", "password": ""},
    )
    assert response.status_code == 400
    assert "required" in response.json()["detail"].lower()
