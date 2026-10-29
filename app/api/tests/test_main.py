from unittest.mock import MagicMock

from fastapi.testclient import TestClient

from main import app, get_db

client = TestClient(app)


def _mock_db(rows=None, insert_id=1):
    cur = MagicMock()
    cur.fetchall.return_value = rows if rows is not None else []
    cur.fetchone.return_value = (insert_id,)

    ctx = MagicMock()
    ctx.__enter__ = MagicMock(return_value=cur)
    ctx.__exit__ = MagicMock(return_value=False)

    conn = MagicMock()
    conn.cursor.return_value = ctx
    return conn


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_list_items_empty():
    app.dependency_overrides[get_db] = lambda: _mock_db(rows=[])
    try:
        response = client.get("/api/items")
        assert response.status_code == 200
        assert response.json() == []
    finally:
        app.dependency_overrides.clear()


def test_list_items():
    rows = [(1, "apple", "a fruit"), (2, "pen", "a tool")]
    app.dependency_overrides[get_db] = lambda: _mock_db(rows=rows)
    try:
        response = client.get("/api/items")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0] == {"id": 1, "name": "apple", "description": "a fruit"}
        assert data[1] == {"id": 2, "name": "pen", "description": "a tool"}
    finally:
        app.dependency_overrides.clear()


def test_create_item():
    app.dependency_overrides[get_db] = lambda: _mock_db(insert_id=42)
    try:
        response = client.post("/api/items", json={"name": "widget", "description": "a thing"})
        assert response.status_code == 201
        assert response.json() == {"id": 42, "name": "widget", "description": "a thing"}
    finally:
        app.dependency_overrides.clear()


def test_create_item_default_description():
    app.dependency_overrides[get_db] = lambda: _mock_db(insert_id=5)
    try:
        response = client.post("/api/items", json={"name": "minimal"})
        assert response.status_code == 201
        body = response.json()
        assert body["id"] == 5
        assert body["name"] == "minimal"
        assert body["description"] == ""
    finally:
        app.dependency_overrides.clear()
