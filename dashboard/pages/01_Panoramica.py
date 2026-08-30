"""Panoramica — il quadro generale di Bologna in dati."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, load_mart

st.title("📊 Bologna in Dati")
st.markdown("**Panoramica** — 15 dataset, 6 temi, dal 1986 ad oggi.")

# ══════════════════════════════════════════════════════════════════════════════
# KPI generali
# ══════════════════════════════════════════════════════════════════════════════

# Popolazione latest — filtra ultimo anno
df_pop_all = load_mart("popolazione_quartiere", "mart_pop_quartiere", 2024)
anno_pop = int(df_pop_all["anno"].max()) if not df_pop_all.empty else 2024
df_pop = df_pop_all[df_pop_all["anno"] == anno_pop] if not df_pop_all.empty else df_pop_all
pop_totale = int(df_pop["residenti"].sum()) if not df_pop.empty else 0

# Varchi ZTL — solo ultimo anno
df_varchi_all = load_mart("varchi_ztl", "mart_varchi_varco", 2026)
anno_ztl = int(df_varchi_all["anno"].max()) if not df_varchi_all.empty else 2026
df_varchi = df_varchi_all[df_varchi_all["anno"] == anno_ztl] if not df_varchi_all.empty else df_varchi_all
n_varchi = len(df_varchi) if not df_varchi.empty else 0
tot_passaggi_ztl = int(df_varchi["totale_passaggi"].sum()) if not df_varchi.empty else 0

# Colonnine bici — solo ultimo anno
df_bici_all = load_mart("colonnine_bici", "mart_colonnine_anno", 2026)
anno_bici = int(df_bici_all["anno"].max()) if not df_bici_all.empty else 2026
df_bici = df_bici_all[df_bici_all["anno"] == anno_bici] if not df_bici_all.empty else df_bici_all
n_colonnine = len(df_bici) if not df_bici.empty else 0
tot_bici = int(df_bici["totale_passaggi"].sum()) if not df_bici.empty else 0

# Qualità aria
df_aria = load_mart("centraline_aria", "mart_aria_stazione", 2026)
n_stazioni = df_aria["stazione"].nunique() if not df_aria.empty else 0

k1, k2, k3, k4 = st.columns(4)
k1.metric("👥 Residenti", fmt_num(pop_totale) if pop_totale else "—", f"{anno_pop}")
k2.metric("🚗 Varchi ZTL", fmt_num(n_varchi), f"{fmt_num(tot_passaggi_ztl)} passaggi · {anno_ztl}")
k3.metric("🚲 Colonnine bici", fmt_num(n_colonnine), f"{fmt_num(tot_bici)} passaggi · {anno_bici}")
k4.metric("🌬️ Stazioni aria", n_stazioni, "2026")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Popolazione per quartiere (latest)
# ══════════════════════════════════════════════════════════════════════════════

st.subheader(f"👥 Popolazione per quartiere ({anno_pop})")

if not df_pop.empty:
    # aggrega per quartiere (somma su tutte le età/sesso/cittadinanza)
    pop_q = (
        df_pop.groupby("quartiere", as_index=False)
        .agg(residenti=("residenti", "sum"))
        .sort_values("residenti", ascending=False)
    )
    chart = (
        alt.Chart(pop_q)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#3b82f6")
        .encode(
            y=alt.Y("quartiere:N", title="", sort="-x"),
            x=alt.X("residenti:Q", title="Residenti", axis=alt.Axis(format="~s")),
            tooltip=["quartiere", alt.Tooltip("residenti:Q", format=",.0f")],
        )
        .properties(height=max(30 * len(pop_q), 180))
    )
    st.altair_chart(chart, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Trend popolazione totale
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("📈 Trend popolazione totale")

if not df_pop_all.empty:
    trend = (
        df_pop_all.groupby("anno", as_index=False)
        .agg(residenti=("residenti", "sum"))
        .sort_values("anno")
    )
    chart = (
        alt.Chart(trend)
        .mark_line(point=True, color="#3b82f6", strokeWidth=2)
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("residenti:Q", title="Residenti", axis=alt.Axis(format="~s")),
            tooltip=["anno", alt.Tooltip("residenti:Q", format=",.0f")],
        )
        .properties(height=280)
    )
    st.altair_chart(chart, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Contenuto dashboard
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🗺️ Cosa contiene")

temi = {
    "👥 Demografia": "Popolazione per quartiere (1986–2024), famiglie, emigrati, convivenze, indici fragilità",
    "🚲 Mobilità": "Varchi ZTL, spire traffico, colonnine bici, matrice WiFi pedonale",
    "🌿 Ambiente": "Qualità dell'aria (NO₂), temperature, precipitazioni",
    "💰 Economia": "Reddito mediano per area statistica, esercizi commerciali",
    "🏛️ PA": "Incarichi di collaborazione del Comune (2012–2026)",
}
for tema, desc in temi.items():
    st.markdown(f"**{tema}** — {desc}")

st.caption("Fonte: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) · CC BY 4.0")
