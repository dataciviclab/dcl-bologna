"""Quartieri — vista cross-tematica per quartiere."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, load_mart

st.title("🗺️ Quartieri di Bologna")
st.markdown("Profilo cross-tematico: popolazione, mobilità, fragilità, reddito, esercizi — tutto insieme.")

# ══════════════════════════════════════════════════════════════════════════════
# Selezione quartiere
# ══════════════════════════════════════════════════════════════════════════════

df_pop = load_mart("popolazione_quartiere", "mart_pop_quartiere", 2024)
quartieri = sorted(df_pop["quartiere"].unique().tolist()) if not df_pop.empty else []
q_selected = st.selectbox("Seleziona quartiere", quartieri, key="q_selector")

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
    q_pop = df_pop[df_pop["quartiere"] == q_selected]
    metrics["👥 Popolazione (2024)"] = fmt_num(int(q_pop["residenti"].sum()))

# Famiglie
df_fam = load_mart("famiglie_tipologia", "mart_famiglie_quartiere", 2024)
if not df_fam.empty:
    q_fam = df_fam[df_fam["quartiere"] == q_selected]
    if not q_fam.empty:
        metrics["👨‍👩‍👧‍👦 Famiglie (2024)"] = fmt_num(int(q_fam["totale_famiglie"].sum()))

# Bici
df_bici = load_mart("colonnine_bici", "mart_colonnine_quartiere", 2026)
if not df_bici.empty:
    q_bici = df_bici[df_bici["quartiere"] == q_selected]
    if not q_bici.empty:
        metrics["🚲 Passaggi bici (2026)"] = fmt_num(int(q_bici["totale_passaggi"].sum()))

# Emigrati
df_emig = load_mart("emigrati_destinazione", "mart_emigrati_quartiere", 2024)
if not df_emig.empty:
    q_emig = df_emig[df_emig["quartiere"] == q_selected]
    if not q_emig.empty:
        metrics["🚶 Emigrati (2024)"] = fmt_num(int(q_emig["totale_emigrati"].sum()))

# Fragilità
df_frag = load_mart("indici_fragilita", "mart_fragilita_quartiere", 2026)
if not df_frag.empty:
    q_frag = df_frag[df_frag["quartiere"] == q_selected]
    if not q_frag.empty:
        metrics["🔍 Fragilità complessiva"] = f"{q_frag['frag_compl_media'].iloc[0]:.2f}"

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
# Radar chart comparativo (tutti i quartieri)
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🕸️ Indici normalizzati (0–1) vs media città")

# Costruisci un mini-dataset con indici normalizzati
radar_data = []
if not df_pop.empty:
    pop_q_all = df_pop.groupby("quartiere", as_index=False).agg(residenti=("residenti", "sum"))
    max_pop = pop_q_all["residenti"].max()
    for _, r in pop_q_all.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Popolazione",
            "valore": r["residenti"] / max_pop if max_pop else 0,
        })

if not df_bici.empty:
    max_bici = df_bici["totale_passaggi"].max()
    for _, r in df_bici.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Bici",
            "valore": r["totale_passaggi"] / max_bici if max_bici else 0,
        })

if not df_frag.empty:
    max_frag = df_frag["frag_compl_media"].max()
    for _, r in df_frag.iterrows():
        radar_data.append({
            "quartiere": r["quartiere"],
            "indice": "Fragilità",
            "valore": r["frag_compl_media"] / max_frag if max_frag else 0,
        })

if radar_data:
    df_radar = pd.DataFrame(radar_data)
    df_radar_q = df_radar[df_radar["quartiere"] == q_selected]
    if not df_radar_q.empty:
        chart = (
            alt.Chart(df_radar_q)
            .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3)
            .encode(
                y=alt.Y("indice:N", title=""),
                x=alt.X("valore:Q", title="Valore normalizzato (0–1)", axis=alt.Axis(format=".1f")),
                color=alt.Color("indice:N", legend=None),
                tooltip=["indice", alt.Tooltip("valore:Q", format=",.2f")],
            )
            .properties(height=150)
        )
        st.altair_chart(chart, width="stretch")
else:
    st.info("Dati insufficienti per il confronto normalizzato.")

st.caption("Dati aggregati da OpenData Comune di Bologna · CC BY 4.0")
