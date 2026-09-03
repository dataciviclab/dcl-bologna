"""Panoramica — il quadro generale di Bologna in dati."""

import json
from pathlib import Path

import altair as alt
import pandas as pd
import pydeck as pdk
import streamlit as st

from sources import fmt_eur, fmt_num, load_mart

st.title("📊 Bologna in Dati")
st.markdown(
    "Cosa siamo, come ci muoviamo, che aria respiriamo, quanto guadagnamo — in un quadro."
)

# ══════════════════════════════════════════════════════════════════════════════
# KPI per tema (1 per tema, con trend vs anno precedente)
# ══════════════════════════════════════════════════════════════════════════════


def _trend_arrow(curr, prev):
    """Ritorna freccia + delta in base alla variazione."""
    if prev is None or prev == 0:
        return ""
    pct = (curr - prev) / prev
    if pct > 0.01:
        return f"+{pct:.1%}"
    elif pct < -0.01:
        return f"{pct:.1%}"
    return "~0%"


# 1. Popolazione
df_pop = load_mart("popolazione_quartiere", "mart_pop_quartiere", 2024)
pop_curr = pop_prev = None
if not df_pop.empty:
    yr = int(df_pop["anno"].max())
    pop_curr = int(df_pop[df_pop["anno"] == yr]["residenti"].sum())
    prev_rows = df_pop[df_pop["anno"] == yr - 1]
    if not prev_rows.empty:
        pop_prev = int(prev_rows["residenti"].sum())

# 2. Varchi ZTL
df_varchi = load_mart("varchi_ztl", "mart_varchi_varco", 2026)
ztl_curr = ztl_prev = None
if not df_varchi.empty:
    yr = int(df_varchi["anno"].max())
    ztl_curr = int(df_varchi[df_varchi["anno"] == yr]["totale_passaggi"].sum())
    prev_rows = df_varchi[df_varchi["anno"] == yr - 1]
    if not prev_rows.empty:
        ztl_prev = int(prev_rows["totale_passaggi"].sum())

# 3. NO₂ medio
df_aria = load_mart("centraline_aria", "mart_aria_stazione", 2026)
no2_curr = no2_prev = None
if not df_aria.empty:
    no2_all = df_aria[df_aria["agente_atm"].str.contains("NO2", case=False, na=False)]
    if not no2_all.empty:
        yr = int(no2_all["anno"].max())
        no2_curr = round(
            float(no2_all[no2_all["anno"] == yr]["media_valore"].mean()), 1
        )
        prev_rows = no2_all[no2_all["anno"] == yr - 1]
        if not prev_rows.empty:
            no2_prev = round(float(prev_rows["media_valore"].mean()), 1)

# 4. Reddito mediano
df_reddito = load_mart("reddito_mediano", "mart_reddito_area", 2026)
reddito_curr = reddito_prev = None
if not df_reddito.empty:
    yr = int(df_reddito["anno"].max())
    reddito_curr = int(
        df_reddito[df_reddito["anno"] == yr]["reddito_imponibile_mediano"].median()
    )
    prev_rows = df_reddito[df_reddito["anno"] == yr - 1]
    if not prev_rows.empty:
        reddito_prev = int(prev_rows["reddito_imponibile_mediano"].median())

# 5. Incarichi PA
df_incarichi = load_mart("incarichi", "mart_incarichi_anno", 2026)
inc_curr = inc_prev = None
if not df_incarichi.empty:
    yr = int(df_incarichi["anno"].max())
    inc_curr = int(df_incarichi[df_incarichi["anno"] == yr]["importo_totale"].sum())
    prev_rows = df_incarichi[df_incarichi["anno"] == yr - 1]
    if not prev_rows.empty:
        inc_prev = int(prev_rows["importo_totale"].sum())

# 6. Esercizi commerciali
df_esercizi = load_mart("esercizi_somministrazione", "mart_esercizi_quartiere", 2026)
eser_curr = None
if not df_esercizi.empty:
    eser_curr = int(df_esercizi["n_esercizi"].sum())

# ── Render KPI ──────────────────────────────────────────────────────────────


k1, k2, k3 = st.columns(3)
with k1:
    st.metric(
        "👥 Residenti",
        fmt_num(pop_curr) if pop_curr else "—",
        _trend_arrow(pop_curr or 0, pop_prev),
    )
with k2:
    st.metric(
        "🚗 Passaggi ZTL",
        fmt_num(ztl_curr) if ztl_curr else "—",
        _trend_arrow(ztl_curr or 0, ztl_prev),
    )
with k3:
    st.metric(
        "🌬️ NO₂ medio",
        f"{no2_curr} µg/m³" if no2_curr else "—",
        _trend_arrow(no2_curr or 0, no2_prev),
    )

k4, k5, k6 = st.columns(3)
with k4:
    st.metric(
        "💰 Reddito mediano",
        fmt_eur(reddito_curr) if reddito_curr else "—",
        _trend_arrow(reddito_curr or 0, reddito_prev),
    )
with k5:
    st.metric(
        "🏛️ Importo incarichi",
        fmt_eur(inc_curr) if inc_curr else "—",
        _trend_arrow(inc_curr or 0, inc_prev),
    )
with k6:
    st.metric("🏪 Esercizi commerciali", fmt_num(eser_curr) if eser_curr else "—")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Mini-mappa quartieri (popolazione)
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🗺️ Bologna per quartieri")

_GEOJSON_PATH = Path(__file__).resolve().parent.parent / "quartieri.geojson"
with open(_GEOJSON_PATH) as f:
    _quartieri_geo = json.load(f)

_POLYGONS = []
for feat in _quartieri_geo["features"]:
    geom = feat["geometry"]
    rings = (
        geom["coordinates"]
        if geom["type"] == "Polygon"
        else [r for p in geom["coordinates"] for r in p]
    )
    for ring in rings:
        _POLYGONS.append(
            {"quartiere": feat["properties"].get("quartiere", ""), "polygon": [ring]}
        )

if not df_pop.empty:
    yr = int(df_pop["anno"].max())
    df_latest = df_pop[df_pop["anno"] == yr]
    agg_pop = df_latest.groupby("quartiere", as_index=False).agg(
        valore=("residenti", "sum")
    )
    agg_pop = agg_pop[agg_pop["quartiere"] != "Senza fissa dimora"]
    valori = dict(zip(agg_pop["quartiere"], agg_pop["valore"]))
    vals = list(valori.values())
    v_max, v_min = max(vals), min(vals)

    def _color(v):
        t = (v - v_min) / (v_max - v_min) if v_max > v_min else 0.5
        r = int(min(255, t * 2 * 255))
        g = int(min(255, (1 - abs(t - 0.5) * 2) * 255))
        b = int(min(255, (1 - t) * 2 * 255))
        return [r, g, b, 200]

    map_data = []
    for poly in _POLYGONS:
        q = poly["quartiere"]
        v = valori.get(q, 0)
        map_data.append(
            {
                "polygon": poly["polygon"],
                "quartiere": q,
                "valore": v,
                "valore_fmt": f"{v:,.0f}",
                "fill_color": _color(v),
            }
        )

    layer = pdk.Layer(
        "PolygonLayer",
        map_data,
        get_polygon="polygon",
        get_fill_color="fill_color",
        get_line_color=[100, 100, 100],
        get_line_width=50,
        line_width_min_pixels=1,
        pickable=True,
        auto_highlight=True,
    )
    tooltip = {
        "html": "<b>{quartiere}</b><br>Residenti: {valore_fmt}",
        "style": {
            "backgroundColor": "rgba(0,0,0,0.8)",
            "color": "white",
            "padding": "8px",
        },
    }
    st.pydeck_chart(
        pdk.Deck(
            layers=[layer],
            initial_view_state=pdk.ViewState(
                latitude=44.495, longitude=11.342, zoom=11.5, pitch=0
            ),
            tooltip=tooltip,
            map_style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
            height=380,
        )
    )
else:
    st.info("Dati popolazione non disponibili per la mappa.")

st.caption(
    "Fonte: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) · CC BY 4.0"
)
