import os

import psycopg
from azure.identity import ManagedIdentityCredential
from fastapi import APIRouter, Depends, FastAPI
from pydantic import BaseModel

_SCOPE = "https://ossrdbms-aad.database.windows.net/.default"

app = FastAPI()
router = APIRouter(prefix="/api")

_credential = ManagedIdentityCredential(client_id=os.environ["AZURE_CLIENT_ID"])


def get_db():
    conn = psycopg.connect(
        host=os.environ["PGHOST"],
        dbname=os.environ["PGDATABASE"],
        user=os.environ["PGUSER"],
        password=_credential.get_token(_SCOPE).token,
        sslmode="require",
    )
    try:
        yield conn
    finally:
        conn.close()


class Item(BaseModel):
    name: str
    description: str = ""


@app.get("/health")
def health():
    return {"status": "ok"}


@router.get("/items")
def list_items(db: psycopg.Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute("SELECT id, name, description FROM items ORDER BY id")
        rows = cur.fetchall()
    return [{"id": row[0], "name": row[1], "description": row[2]} for row in rows]


@router.post("/items", status_code=201)
def create_item(item: Item, db: psycopg.Connection = Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            "INSERT INTO items (name, description) VALUES (%s, %s) RETURNING id",
            (item.name, item.description),
        )
        new_id = cur.fetchone()[0]
    db.commit()
    return {"id": new_id, "name": item.name, "description": item.description}


app.include_router(router)
