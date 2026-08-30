"""Query SQL — Interroga direttamente i dati."""

from pathlib import Path

from lab_connectors.duckdb.sql_page import render_sql_query
from sources import get_registry

registry = get_registry()

render_sql_query(
    registry=registry,
    prefix="",
    default_slug="popolazione_quartiere",
    title="🧪 Query SQL",
    description=(
        "Interroga direttamente i dati. Scrivi SQL su ``clean_input`` — "
        "viene risolta automaticamente sui Parquet locali."
    ),
)
