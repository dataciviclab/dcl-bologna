"""Data sources per la dashboard dcl-bologna.

Pattern standard: wrappa lab_connectors con @st.cache_data.
Per ora i dati sono locali (out/data/) — quando saranno su GCS,
basta swappare load_mart per usare lab_connectors.duckdb.queries.
"""

from __future__ import annotations

from pathlib import Path

import duckdb
import pandas as pd
import streamlit as st

from lab_connectors.formatters import fmt_eur, fmt_num, fmt_pct
from lab_connectors.registry import load_registry

# Re-export per comodità delle pagine
__all__ = ["fmt_num", "fmt_pct", "fmt_eur", "load_mart", "load_clean", "run_sql", "load_registry"]

# ── Path (temporaneo — rimuovere quando i dati saranno su GCS) ────────────────

REPO = Path(__file__).resolve().parent.parent
CLEAN_DIR = REPO / "out" / "data" / "clean"
MART_DIR = REPO / "out" / "data" / "mart"
REGISTRY_PATH = REPO / "registry" / "registry.json"


def _parquet_path(layer: str, slug: str, table: str, year: int | None = None) -> Path | None:
    """Ritorna il path di un parquet clean o mart (locale).

    clean: out/data/clean/<slug>/<year>/<slug>_<year>_clean.parquet
    mart:  out/data/mart/<slug>/<year>/<table>.parquet
          oppure out/data/mart/<slug>/<table>.parquet (flat, es. spire_trend)
    """
    base = MART_DIR if layer == "mart" else CLEAN_DIR
    if layer == "mart":
        if year:
            p = base / slug / str(year) / f"{table}.parquet"
            if p.exists():
                return p
        p = base / slug / f"{table}.parquet"
        return p if p.exists() else None
    else:
        p = base / slug / str(year) / f"{slug}_{year}_clean.parquet"
        return p if p.exists() else None


# ── Cached loaders ────────────────────────────────────────────────────────────


def _read_parquet(path: Path) -> pd.DataFrame:
    with duckdb.connect() as con:
        return con.sql(f"SELECT * FROM read_parquet('{path}')").df()


@st.cache_data(ttl=3600, show_spinner=False)
def load_mart(slug: str, table: str, year: int | None = None) -> pd.DataFrame:
    """Carica un singolo mart table (cached 1h).

    Quando i dati saranno su GCS, sostituire con:
        from lab_connectors.duckdb.queries import load_mart_table
        return load_mart_table(slug, table, year)
    """
    p = _parquet_path("mart", slug, table, year)
    if p is None:
        return pd.DataFrame()
    return _read_parquet(p)


@st.cache_data(ttl=3600, show_spinner=False)
def load_clean(slug: str, year: int) -> pd.DataFrame:
    """Carica il clean layer per un anno (cached 1h)."""
    p = _parquet_path("clean", slug, None, year)
    if p is None:
        return pd.DataFrame()
    return _read_parquet(p)


@st.cache_data(ttl=3600, show_spinner=False)
def run_sql(sql: str) -> pd.DataFrame:
    """Esegue SQL arbitrario sui parquet locali via DuckDB (cached 1h)."""
    with duckdb.connect() as con:
        return con.sql(sql).df()


# ── Registry ──────────────────────────────────────────────────────────────────


@st.cache_data(ttl=3600, show_spinner=False)
def get_registry():
    """Carica il registry del repo via lab_connectors."""
    return load_registry(REGISTRY_PATH)
