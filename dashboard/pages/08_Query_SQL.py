"""Query SQL — Interroga direttamente i dati."""

from pathlib import Path

from lab_connectors.duckdb.sql_page import render_sql_query
from lab_connectors.registry import load_registry

_REPO = Path(__file__).resolve().parent.parent.parent
render_sql_query(
    registry=load_registry(_REPO / "registry" / "registry.json"),
    prefix="",
    default_slug="popolazione-quartiere",
    title="🧪 Query SQL",
    description=(
        "Interroga direttamente i dati. Scrivi SQL su ``clean_input`` — "
        "viene risolta automaticamente sui Parquet."
    ),
)
