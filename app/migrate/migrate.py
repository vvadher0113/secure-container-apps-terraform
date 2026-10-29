#!/usr/bin/env python3
import os
import sys

import psycopg
from azure.identity import ManagedIdentityCredential
from psycopg import sql


def main() -> None:
    credential = ManagedIdentityCredential(client_id=os.environ["AZURE_CLIENT_ID"])
    token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default").token

    conn = psycopg.connect(
        host=os.environ["PGHOST"],
        dbname=os.environ["PGDATABASE"],
        user=os.environ["PGUSER"],
        password=token,
        sslmode="require",
    )
    conn.autocommit = True

    role_name = os.environ["APP_ROLE_NAME"]
    role_oid = os.environ["APP_ROLE_OBJECT_ID"]

    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS items (
                id          SERIAL PRIMARY KEY,
                name        TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT ''
            )
        """)

        cur.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role_name,))
        if cur.fetchone() is None:
            cur.execute(
                "SELECT pgaadauth_create_principal_with_oid(%s, %s, 'service', false, false)",
                (role_name, role_oid),
            )

        cur.execute(
            sql.SQL("GRANT SELECT, INSERT ON items TO {}").format(sql.Identifier(role_name))
        )
        cur.execute(
            sql.SQL("GRANT USAGE, SELECT ON SEQUENCE items_id_seq TO {}").format(
                sql.Identifier(role_name)
            )
        )

    conn.close()
    print("Migration complete.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Migration failed: {exc}", file=sys.stderr, flush=True)
        sys.exit(1)
