"""
Utility to (re)write the Realtime postgres_cdc_rls extension settings
with AES-128-ECB + PKCS7 base64-encoded string fields using DB_ENC_KEY.

Run inside the backend container:
  docker compose exec backend python scripts/update_realtime_ext.py
"""

from __future__ import annotations

import base64
import os
import sys
from dataclasses import dataclass

import psycopg2
import psycopg2.extras as extras
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding


@dataclass
class Config:
    database_url: str
    db_enc_key: bytes
    tenant_external_id: str = "realtime"
    extension_type: str = "postgres_cdc_rls"


def get_config() -> Config:
    try:
        database_url = os.environ["DATABASE_URL"]
    except KeyError:
        print("ERROR: DATABASE_URL env var is required", file=sys.stderr)
        sys.exit(1)

    db_enc_key_str = os.environ.get("DB_ENC_KEY", "0123456789abcdef")
    if len(db_enc_key_str) != 16:
        print(
            f"WARNING: DB_ENC_KEY length is {len(db_enc_key_str)}; AES-128 expects 16 bytes. Using provided value anyway.",
            file=sys.stderr,
        )
    return Config(database_url=database_url, db_enc_key=db_enc_key_str.encode("utf-8"))


def aes128_ecb_b64_encrypt(key: bytes, s: str) -> str:
    padder = padding.PKCS7(128).padder()
    data = padder.update(s.encode("utf-8")) + padder.finalize()
    cipher = Cipher(algorithms.AES(key), modes.ECB())
    encryptor = cipher.encryptor()
    ct = encryptor.update(data) + encryptor.finalize()
    return base64.b64encode(ct).decode("ascii")


def main() -> int:
    cfg = get_config()

    # Values we want to store for the local dev environment
    # Note: booleans/ints stay as-is (not encrypted). Strings are encrypted.
    plaintext = {
        "db_ip": "db",
        "db_ssl": False,
        "region": "local",
        "db_host": "db",
        "db_name": "postgres",
        "db_port": 5432,
        "db_user": "postgres",
        "slot_name": "supabase_realtime_rls",
        "ip_version": "IPv4",
        # Prefer POSTGRES_PASSWORD from env if present, fallback to compose default
        "db_password": os.environ.get("POSTGRES_PASSWORD", "yoursupersecretandlongpostgrespassword"),
        "ssl_enforced": False,
        "temporary_slot": True,
    }

    # Encrypt ALL fields as strings because Realtime decrypts values blindly.
    # Booleans/ints are stringified (true/false lowercase, numbers as decimal).
    def to_plain_string(val):
        if isinstance(val, bool):
            return "true" if val else "false"
        return str(val)

    settings = {k: aes128_ecb_b64_encrypt(cfg.db_enc_key, to_plain_string(v)) for k, v in plaintext.items()}

    print("New settings payload to write:")
    for k, v in settings.items():
        print(f"  {k}: {v}")

    # Update row
    conn = psycopg2.connect(cfg.database_url)
    try:
        with conn, conn.cursor() as cur:
            cur.execute(
                """
                update extensions
                   set settings = %s
                 where tenant_external_id = %s
                   and type = %s
                """,
                (extras.Json(settings), cfg.tenant_external_id, cfg.extension_type),
            )

        with conn, conn.cursor() as cur:
            cur.execute(
                """
                select settings::text
                  from extensions
                 where tenant_external_id = %s and type = %s
                """,
                (cfg.tenant_external_id, cfg.extension_type),
            )
            row = cur.fetchone()
            print("\nRow after update:\n", row[0])
    finally:
        conn.close()

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
