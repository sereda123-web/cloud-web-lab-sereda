import app as app_module
from app import app

TEST_TOKEN = "test-token-for-ci"


def admin_headers(monkeypatch):
    monkeypatch.setattr(app_module, "ADMIN_TOKEN", TEST_TOKEN)
    return {"Authorization": f"Bearer {TEST_TOKEN}"}


def test_index():
    client = app.test_client()
    response = client.get("/")

    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "running"


def test_admin_stats_requires_token():
    client = app.test_client()
    response = client.get("/api/admin/stats")

    assert response.status_code == 401  # EXPERIMENT: для експерименту змініть на 200


def test_create_record_requires_token():
    client = app.test_client()
    response = client.post(
        "/api/records",
        json={
            "student_name": "Test",
            "subject": "ci",
            "status": "present"
        }
    )

    assert response.status_code == 401


def test_wrong_token_is_rejected(monkeypatch):
    admin_headers(monkeypatch)
    client = app.test_client()
    response = client.get(
        "/api/admin/stats",
        headers={"Authorization": "Bearer wrong-token"}
    )

    assert response.status_code == 401


def test_create_record_requires_required_fields(monkeypatch):
    headers = admin_headers(monkeypatch)
    client = app.test_client()
    response = client.post(
        "/api/records",
        headers=headers,
        json={"student_name": "", "subject": "ci"}
    )

    assert response.status_code == 400


def test_create_record_rejects_invalid_status(monkeypatch):
    headers = admin_headers(monkeypatch)
    client = app.test_client()
    response = client.post(
        "/api/records",
        headers=headers,
        json={"student_name": "Test", "subject": "ci", "status": "hacked"}
    )

    assert response.status_code == 400


def test_health_returns_503_without_database(monkeypatch):
    monkeypatch.setattr(app_module, "DATABASE_URL", "")
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 503
    assert response.get_json()["database"] == "error"


def test_public_endpoints_do_not_leak_secrets(monkeypatch):
    monkeypatch.setattr(app_module, "ADMIN_TOKEN", TEST_TOKEN)
    client = app.test_client()
    body = client.get("/").get_data(as_text=True)

    assert TEST_TOKEN not in body
    assert "postgresql://" not in body
