"""Data sources per la dashboard dcl-bologna.

Layer sottile che wrappa DuckDB su parquet locali (out/data/clean|mart).
Quando i dati saranno su GCS, basta cambiare i path in _base_path().
"""

from __future__ import annotations

from pathlib import Path

import duckdb
import pandas as pd
import streamlit as st

# ── Path ──────────────────────────────────────────────────────────────────────

REPO = Path(__file__).resolve().parent.parent
CLEAN_DIR = REPO / "out" / "data" / "clean"
MART_DIR = REPO / "out" / "data" / "mart"
REGISTRY_PATH = REPO / "registry" / "registry.json"


def _parquet_path(layer: str, slug: str, table: str, year: int | None = None) -> Path | None:
    """Ritorna il path di un parquet clean o mart.

    clean: out/data/clean/<slug>/<year>/<slug>_<year>_clean.parquet
    mart:  out/data/mart/<slug>/<year>/<table>.parquet
          oppure out/data/mart/<slug>/<table>.parquet (senza anno, es. spire_trend)
    """
    base = MART_DIR if layer == "mart" else CLEAN_DIR
    if layer == "mart":
        if year:
            p = base / slug / str(year) / f"{table}.parquet"
            if p.exists():
                return p
        # fallback: senza anno (es. spire_trend)
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
    """Carica un singolo mart table (cached 1h)."""
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


@st.cache_data(ttl=3600, show_spinner=False)
def load_registry() -> list[dict]:
    """Carica il registry.json del repo."""
    import json

    if not REGISTRY_PATH.exists():
        return []
    with open(REGISTRY_PATH) as f:
        data = json.load(f)
    return data.get("datasets", [])


# ── Formatters ────────────────────────────────────────────────────────────────


def fmt_num(n: float | int) -> str:
    """Formatta numeri: 1234567 → 1.234.567."""
    return f"{int(n):,}".replace(",", ".")


def fmt_pct(p: float) -> str:
    return f"{p:.1f}%"


def fmt_mm(mm: float) -> str:
    return f"{mm:.0f} mm"
