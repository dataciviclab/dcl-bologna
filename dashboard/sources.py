"""Data sources per la dashboard dcl-bologna.

Wrappa lab_connectors con @st.cache_data.
Su Streamlit Cloud legge da GCS (prefix=bologna); in locale da out/data/.
"""

from __future__ import annotations

import pandas as pd
import streamlit as st

from lab_connectors.duckdb.queries import load_mart_flat, load_mart_table
from lab_connectors.formatters import fmt_eur, fmt_num, fmt_pct

__all__ = ["fmt_num", "fmt_pct", "fmt_eur", "load_mart", "run_sql"]

PREFIX = "bologna"


@st.cache_data(ttl=3600, show_spinner=False)
def load_mart(slug: str, table: str, year: int | None = None) -> pd.DataFrame:
    """Carica un singolo mart table (cached 1h)."""
    if year is None:
        return load_mart_flat(slug, table, prefix=PREFIX)
    return load_mart_table(slug, table, year, prefix=PREFIX)


@st.cache_data(ttl=3600, show_spinner=False)
def run_sql(sql: str) -> pd.DataFrame:
    """Esegue SQL arbitrario sui parquet locali via DuckDB (cached 1h)."""
    import duckdb
    with duckdb.connect() as con:
        return con.sql(sql).df()
