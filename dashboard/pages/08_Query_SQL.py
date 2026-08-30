"""Query SQL — esplorazione libera con DuckDB sui parquet locali."""

import time

import duckdb
import streamlit as st

from sources import MART_DIR, CLEAN_DIR, fmt_num

st.title("🧪 Query SQL")
st.markdown("Esegui query SQL direttamente sui parquet locali via DuckDB.")

# ── Info ──────────────────────────────────────────────────────────────────────

with st.expander("ℹ️ Come funziona", expanded=False):
    st.markdown("""
**Layer disponibili:**
- **clean**: `out/data/clean/<slug>/<year>/<slug>_<year>_clean.parquet`
- **mart**: `out/data/mart/<slug>/<year>/<table>.parquet`

**Esempio query:**
```sql
SELECT quartiere, SUM(residenti) as pop
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
GROUP BY quartiere ORDER BY pop DESC
```
""")

# ── Templates ─────────────────────────────────────────────────────────────────

templates = {
    "🏠 Popolazione per quartiere (2024)": """
SELECT quartiere, SUM(residenti) as residenti
FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
WHERE anno = 2024
GROUP BY quartiere ORDER BY residenti DESC
""",
    "🚗 Top 10 varchi ZTL (2026)": """
SELECT nome_varco, SUM(totale_passaggi) as passaggi,
       ROUND(SUM(totale_passaggi) * 1.0 / COUNT(DISTINCT data::date), 0) as media_giorno
FROM read_parquet('out/data/clean/varchi_ztl/2026/varchi_ztl_2026_clean.parquet')
GROUP BY nome_varco ORDER BY passaggi DESC LIMIT 10
""",
    "🚲 Passaggi bici per colonnina (2026)": """
SELECT colonnina, quartiere, SUM(totale) as passaggi
FROM read_parquet('out/data/clean/colonnine_bici/2026/colonnine_bici_2026_clean.parquet')
GROUP BY colonnina, quartiere ORDER BY passaggi DESC
""",
    "🌬️ NO₂ medio per stazione (2026)": """
SELECT stazione, ROUND(AVG(value), 1) as no2_medio
FROM read_parquet('out/data/clean/centraline_aria/2026/centraline_aria_2026_clean.parquet')
WHERE agente_atm LIKE '%NO2%'
GROUP BY stazione ORDER BY no2_medio DESC
""",
    "💰 Reddito mediano top/bottom (2026)": """
SELECT area_statistica, reddito_imponibile_mediano, numero_contribuenti
FROM read_parquet('out/data/clean/reddito_mediano/2026/reddito_mediano_2026_clean.parquet')
WHERE anno = 2026
ORDER BY reddito_imponibile_mediano DESC
""",
}

template_names = list(templates.keys())
selected = st.selectbox("Template (opzionale)", ["Scrivi la tua query..."] + template_names, key="sql_template")

default_sql = templates.get(selected, "")
sql = st.text_area("SQL", value=default_sql, height=200, key="sql_input",
                   placeholder="SELECT * FROM read_parquet('out/data/clean/...') LIMIT 10")

# ── Esegui ────────────────────────────────────────────────────────────────────

if st.button("▶️ Esegui", key="sql_run") and sql.strip():
    with st.spinner("Esecuzione..."):
        start = time.time()
        try:
            con = duckdb.connect()
            result = con.sql(sql).df()
            elapsed = time.time() - start
            st.success(f"✅ {len(result)} righe · {elapsed:.2f}s")
            st.dataframe(result, width="stretch", height=min(35 * len(result) + 35, 600))
        except Exception as e:
            st.error(f"❌ Errore: {e}")

# ── Info duckdb ───────────────────────────────────────────────────────────────

st.markdown("---")
st.caption(f"📦 DuckDB {duckdb.__version__} · Parquet files da out/data/")
