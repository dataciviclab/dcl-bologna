"""Data sources per la dashboard dcl-bologna.

Wrappa lab_connectors con @st.cache_data. I dati sono locali (out/data/) —
quando saranno su GCS, basta rimuovere local_root (auto-detect GCS).
"""

from __future__ import annotations

import duckdb
import pandas as pd
import streamlit as st

from lab_connectors.duckdb.queries import load_mart_flat, load_mart_table
from lab_connectors.formatters import fmt_eur, fmt_num, fmt_pct
from lab_connectors.registry import load_registry

__all__ = ["fmt_num", "fmt_pct", "fmt_eur", "load_mart", "run_sql"]


@st.cache_data(ttl=3600, show_spinner=False)
def load_mart(slug: str, table: str, year: int | None = None) -> pd.DataFrame:
    """Carica un singolo mart table (cached 1h).

    year=None → load_mart_flat (tabelle non partizionate per anno).
    Usa lab_connectors con local_root auto-detect: risolve out/data/
    dal cwd (funziona sia da repo root che da dashboard/).
    """
    if year is None:
        return load_mart_flat(slug, table)
    return load_mart_table(slug, table, year)


@st.cache_data(ttl=3600, show_spinner=False)
def run_sql(sql: str) -> pd.DataFrame:
    """Esegue SQL arbitrario sui parquet locali via DuckDB (cached 1h)."""
    with duckdb.connect() as con:
        return con.sql(sql).df()
