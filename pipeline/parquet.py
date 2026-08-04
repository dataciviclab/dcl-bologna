"""Contratto condiviso di ispezione Parquet via DuckDB.

Unico punto canonico per leggere schema e conteggio di un file Parquet.
Usato da fetch.py (validazione post-download) e check.py (registry/status).

Nota sintassi: DuckDB non accetta `DESCRIBE read_parquet(...)` su una
table function — serve la forma `(DESCRIBE SELECT * FROM read_parquet(...))`.
Mantenere questo helper come unica fonte del pattern.
"""
import duckdb


def inspect_parquet(path):
    """Ritorna (columns, records) per un file Parquet.

    columns: lista di tuple (column_name, column_type), ordinate per nome.
    records: numero di righe.
    """
    con = duckdb.connect()
    columns = con.execute(
        f"SELECT column_name, column_type "
        f"FROM (DESCRIBE SELECT * FROM read_parquet('{path}')) "
        f"ORDER BY column_name"
    ).fetchall()
    records = con.execute(
        f"SELECT count(*) FROM read_parquet('{path}')"
    ).fetchone()[0]
    return columns, records
