"""Quartieri — mappa choropleth + profilo cross-tematico."""

import json
from pathlib import Path

import altair as alt
import pandas as pd
import pydeck as pdk
import streamlit as st

from sources import fmt_num, load_mart

st.title("🗺️ Quartieri di Bologna")
st.markdown("Mappa interattiva e profilo cross-tematico: popolazione, mobilità, fragilità.")

# ══════════════════════════════════════════════════════════════════════════════
# GeoJSON quartieri (boundaries reali da OpenData Comune di Bologna)
# ══════════════════════════════════════════════════════════════════════════════

_GEOJSON_PATH = Path(__file__).resolve().parent.parent / "quartieri.geojson"
with open(_GEOJSON_PATH) as f:
    _quartieri_geo = json.load(f)

# Pre-converti GeoJSON → lista poligoni pydeck (formato PolygonLayer)
_POLYGONS = []
for feat in _quartieri_geo["features"]:
    geom = feat["geometry"]
    coords = geom["coordinates"]
    # Polygon → [[ring]]; MultiPolygon → [[[ring]], ...]
    if geom["type"] == "Polygon":
        rings = coords
    else:
        rings = [ring for poly in coords for ring in poly]
    for ring in rings:
        # deck.gl vuole [lng, lat] — già nel formato corretto
        _POLYGONS.append({
            "quartiere": feat["properties"].get("quartiere", ""),
            "polygon": [ring],
        })

# ══════════════════════════════════════════════════════════════════════════════
# Choropleth interattiva
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🗺️ Mappa quartieri")

INDICATORI = {
    "Popolazione": ("popolazione_quartiere", "mart_pop_quartiere", "residenti", "sum", "Residenti"),
    "Fragilità complessiva": ("indici_fragilita", "mart_fragilita_quartiere", "frag_compl_media", "mean", "Indice fragilità"),
    "Passaggi bici": ("colonnine_bici", "mart_colonnine_quartiere", "totale_passaggi", "sum", "Passaggi bici"),
    "Emigrati": ("emigrati_destinazione", "mart_emigrati_quartiere", "totale_emigrati", "sum", "Emigrati"),
    "Famiglie": ("famiglie_tipologia", "mart_famiglie_quartiere", "totale_famiglie", "sum", "Famiglie"),
}

sel_indicatore = st.selectbox("Indicatore", list(INDICATORI.keys()), key="choropleth_ind")

slug, table, col, agg, col_label = INDICATORI[sel_indicatore]
df_map = load_mart(slug, table, 2026 if "fragilita" in slug or "bici" in slug else 2024)

# Aggrega per quartiere (ultimo anno disponibile)
if not df_map.empty and col in df_map.columns and "anno" in df_map.columns:
    latest_year = int(df_map["anno"].max())
    df_latest = df_map[df_map["anno"] == latest_year]
    agg_map = df_latest.groupby("quartiere", as_index=False).agg(valore=(col, agg))
    agg_map = agg_map[agg_map["quartiere"] != "Senza fissa dimora"]
elif not df_map.empty and col in df_map.columns:
    agg_map = df_map.groupby("quartiere", as_index=False).agg(valore=(col, agg))
    agg_map = agg_map[agg_map["quartiere"] != "Senza fissa dimora"]
else:
    agg_map = pd.DataFrame(columns=["quartiere", "valore"])

valori = dict(zip(agg_map["quartiere"], agg_map["valore"]))

# Color scale: blu (basso) → giallo → rosso (alto), 0–255
vals = list(valori.values())
v_max = max(vals) if vals else 1
v_min = min(vals) if vals else 0

def _color(v):
    t = (v - v_min) / (v_max - v_min) if v_max > v_min else 0.5
    r = int(min(255, t * 2 * 255))
    g = int(min(255, (1 - abs(t - 0.5) * 2) * 255))
    b = int(min(255, (1 - t) * 2 * 255))
    return [r, g, b, 200]

# Build data per PolygonLayer
data = []
for poly in _POLYGONS:
    q = poly["quartiere"]
    v = valori.get(q, 0)
    data.append({
        "polygon": poly["polygon"],
        "quartiere": q,
        "valore": v,
        "valore_fmt": f"{v:,.0f}",
        "fill_color": _color(v),
    })

layer = pdk.Layer(
    "PolygonLayer",
    data,
    get_polygon="polygon",
    get_fill_color="fill_color",
    get_line_color=[100, 100, 100],
    get_line_width=50,
    line_width_min_pixels=1,
    filled=True,
    stroked=True,
    pickable=True,
    auto_highlight=True,
)

tooltip = {
    "html": f"<b>{{quartiere}}</b><br>{col_label}: {{valore_fmt}}",
    "style": {"backgroundColor": "rgba(0,0,0,0.8)", "color": "white", "padding": "8px"},
}

view = pdk.ViewState(latitude=44.495, longitude=11.342, zoom=11, pitch=0)

st.pydeck_chart(pdk.Deck(
    layers=[layer],
    initial_view_state=view,
    tooltip=tooltip,
    map_style="https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
    height=450,
))

# ══════════════════════════════════════════════════════════════════════════════
# Selezione quartiere per profilo dettagliato
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")

df_pop = load_mart("popolazione_quartiere", "mart_pop_quartiere", 2024)
quartieri = sorted(df_pop["quartiere"].unique().tolist()) if not df_pop.empty else []
q_selected = st.selectbox("Seleziona quartiere per il profilo", quartieri, key="q_selector")

if not q_selected:
    st.stop()

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Profilo complessivo
# ══════════════════════════════════════════════════════════════════════════════

st.subheader(f"📊 Profilo {q_selected}")

metrics = {}

# Popolazione
if not df_pop.empty:
    # Popolazione — filtra ultimo anno
    latest_pop_year = int(df_pop["anno"].max())
    q_pop = df_pop[(df_pop["quartiere"] == q_selected) & (df_pop["anno"] == latest_pop_year)]
    metrics["👥 Popolazione"] = fmt_num(int(q_pop["residenti"].sum()))

# Famiglie — filtra ultimo anno
df_fam = load_mart("famiglie_tipologia", "mart_famiglie_quartiere", 2024)
if not df_fam.empty:
    latest_fam_year = int(df_fam["anno"].max())
    q_fam = df_fam[(df_fam["quartiere"] == q_selected) & (df_fam["anno"] == latest_fam_year)]
    if not q_fam.empty:
        metrics["👨‍👩‍👧‍👦 Famiglie"] = fmt_num(int(q_fam["totale_famiglie"].sum()))

# Bici
df_bici = load_mart("colonnine_bici", "mart_colonnine_quartiere", 2026)
if not df_bici.empty:
    q_bici = df_bici[df_bici["quartiere"] == q_selected]
    if not q_bici.empty:
        metrics["🚲 Passaggi bici (2026)"] = fmt_num(int(q_bici["totale_passaggi"].sum()))

# Emigrati — filtra ultimo anno
df_emig = load_mart("emigrati_destinazione", "mart_emigrati_quartiere", 2024)
if not df_emig.empty:
    latest_emig_year = int(df_emig["anno"].max())
    q_emig = df_emig[(df_emig["quartiere"] == q_selected) & (df_emig["anno"] == latest_emig_year)]
    if not q_emig.empty:
        metrics["🚶 Emigrati"] = fmt_num(int(q_emig["totale_emigrati"].sum()))

# Fragilità — filtra ultimo anno
df_frag = load_mart("indici_fragilita", "mart_fragilita_quartiere", 2026)
if not df_frag.empty:
    latest_frag_year = int(df_frag["anno"].max())
    q_frag = df_frag[(df_frag["quartiere"] == q_selected) & (df_frag["anno"] == latest_frag_year)]
    if not q_frag.empty:
        metrics["🔍 Fragilità"] = f"{q_frag['frag_compl_media'].iloc[0]:.1f}"

# Mostra KPI in colonne
if metrics:
    cols = st.columns(min(len(metrics), 4))
    for i, (label, value) in enumerate(metrics.items()):
        cols[i % len(cols)].metric(label, value)

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Trend popolazione del quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("📈 Trend popolazione")

if not df_pop.empty:
    q_trend = df_pop[df_pop["quartiere"] == q_selected].sort_values("anno")
    if not q_trend.empty:
        chart = (
            alt.Chart(q_trend)
            .mark_line(point=True, color="#3b82f6", strokeWidth=2)
            .encode(
                x=alt.X("anno:O", title="Anno"),
                y=alt.Y("residenti:Q", title="Residenti"),
                tooltip=["anno", alt.Tooltip("residenti:Q", format=",.0f")],
            )
            .properties(height=280)
        )
        st.altair_chart(chart, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Indici normalizzati (0–1) per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🕸️ Indici vs media città (1.0 = media)")

# Costruisci un mini-dataset con indici rispetto alla media città
radar_data = []
if not df_pop.empty:
    pop_q_all = df_pop.groupby("quartiere", as_index=False).agg(residenti=("residenti", "sum"))
    mean_pop = pop_q_all["residenti"].mean()
    for _, r in pop_q_all.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Popolazione",
            "valore": r["residenti"] / mean_pop if mean_pop else 0,
        })

if not df_bici.empty:
    mean_bici = df_bici["totale_passaggi"].mean()
    for _, r in df_bici.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Bici",
            "valore": r["totale_passaggi"] / mean_bici if mean_bici else 0,
        })

if not df_frag.empty:
    mean_frag = df_frag["frag_compl_media"].mean()
    for _, r in df_frag.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Fragilità",
            "valore": r["frag_compl_media"] / mean_frag if mean_frag else 0,
        })

if radar_data:
    df_radar = pd.DataFrame(radar_data)
    df_radar_q = df_radar[df_radar["quartiere"] == q_selected]
    if not df_radar_q.empty:
        bars = (
            alt.Chart(df_radar_q)
            .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3)
            .encode(
                y=alt.Y("indice:N", title=""),
                x=alt.X("valore:Q", title="Rapporto vs media città (1.0 = media)", axis=alt.Axis(format=".1f")),
                color=alt.Color("indice:N", legend=None),
                tooltip=["indice", alt.Tooltip("valore:Q", format=".2f")],
            )
        )
        rule = alt.Chart(pd.DataFrame({"x": [1.0]})).mark_rule(color="white", strokeDash=[4, 4], strokeWidth=1.5).encode(x="x:Q")
        st.altair_chart((bars + rule).properties(height=150), width="stretch")
else:
    st.info("Dati insufficienti per il confronto normalizzato.")

st.caption("Dati aggregati da OpenData Comune di Bologna · CC BY 4.0")
