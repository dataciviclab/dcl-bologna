"""Demografia — popolazione, famiglie, emigrati, convivenze, fragilità."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, fmt_pct, load_mart

st.title("👥 Popolazione & Quartieri")
st.markdown("Serie storiche demografiche di Bologna per quartiere — dal 1986 ad oggi.")

df_pop_all = load_mart("popolazione_quartiere", "mart_pop_quartiere", 2024)
anni_pop = sorted(df_pop_all["anno"].unique()) if not df_pop_all.empty else [2024]

col_f1, col_f2 = st.columns(2)
with col_f1:
    anno_pop = st.selectbox("Anno", anni_pop, index=len(anni_pop) - 1, key="demo_anno")
with col_f2:
    q_opts = ["Tutti"] + sorted(df_pop_all["quartiere"].unique().tolist()) if not df_pop_all.empty else ["Tutti"]
    quartiere = st.selectbox("Quartiere", q_opts, key="demo_quartiere")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Popolazione per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.subheader(f"👥 Popolazione per quartiere — {anno_pop}")

df_anno = df_pop_all[df_pop_all["anno"] == anno_pop] if not df_pop_all.empty else pd.DataFrame()
if not df_anno.empty:
    pop_q = (
        df_anno.groupby("quartiere", as_index=False)
        .agg(residenti=("residenti", "sum"), rank=("rank_quartiere", "first"))
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
        .properties(height=max(25 * len(pop_q), 120))
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Nessun dato popolazione per questo anno.")

# ══════════════════════════════════════════════════════════════════════════════
# Trend per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")
st.subheader("📈 Trend storico per quartiere")

if not df_pop_all.empty:
    df_trend = df_pop_all.copy()
    if quartiere != "Tutti":
        df_trend = df_trend[df_trend["quartiere"] == quartiere]

    trend = (
        df_trend.groupby(["anno", "quartiere"], as_index=False)
        .agg(residenti=("residenti", "sum"))
        .sort_values(["quartiere", "anno"])
    )
    color_enc = (
        alt.Color("quartiere:N", title="Quartiere")
        if quartiere == "Tutti"
        else alt.value("#3b82f6")
    )
    chart = (
        alt.Chart(trend)
        .mark_line(point=True, strokeWidth=1.5)
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("residenti:Q", title="Residenti", axis=alt.Axis(format="~s")),
            color=color_enc,
            tooltip=["anno", "quartiere", alt.Tooltip("residenti:Q", format=",.0f")],
        )
        .properties(height=320)
    )
    st.altair_chart(chart, width="stretch")

# ══════════════════════════════════════════════════════════════════════════════
# Trend demografico (CAGR)
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")
st.subheader("📉 Variazione 1986 → 2024")

df_trend_tab = load_mart("popolazione_quartiere", "mart_pop_trend", 2024)
if not df_trend_tab.empty:
    display = df_trend_tab[["quartiere", "residenti_primo", "residenti_ultimo", "variazione_pct", "cagr_pct"]].copy()
    display.columns = ["Quartiere", "1986", "2024", "Var %", "CAGR %"]
    st.dataframe(
        display.sort_values("Var %", ascending=False),
        column_config={
            "1986": st.column_config.NumberColumn(format=",.0f"),
            "2024": st.column_config.NumberColumn(format=",.0f"),
            "Var %": st.column_config.NumberColumn(format="%.1f%%"),
            "CAGR %": st.column_config.NumberColumn(format="%.2f%%"),
        },
        hide_index=True,
        width="stretch",
    )

# ══════════════════════════════════════════════════════════════════════════════
# Famiglie per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")
st.subheader("👨‍👩‍👧‍👦 Famiglie per quartiere (2024)")

df_fam = load_mart("famiglie_tipologia", "mart_famiglie_quartiere", 2024)
if not df_fam.empty:
    fam_q = df_fam.sort_values("totale_famiglie", ascending=False)
    chart = (
        alt.Chart(fam_q)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#8b5cf6")
        .encode(
            y=alt.Y("quartiere:N", title="", sort="-x"),
            x=alt.X("totale_famiglie:Q", title="Famiglie", axis=alt.Axis(format="~s")),
            tooltip=["quartiere", alt.Tooltip("totale_famiglie:Q", format=",.0f")],
        )
        .properties(height=max(25 * len(fam_q), 120))
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Dati famiglie non disponibili.")

# ══════════════════════════════════════════════════════════════════════════════
# Emigrati per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")
st.subheader("🚶 Emigrati per quartiere (2024)")

df_emig = load_mart("emigrati_destinazione", "mart_emigrati_quartiere", 2024)
if not df_emig.empty:
    emig = df_emig.sort_values("totale_emigrati", ascending=False)
    chart = (
        alt.Chart(emig)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#ef4444")
        .encode(
            y=alt.Y("quartiere:N", title="", sort="-x"),
            x=alt.X("totale_emigrati:Q", title="Emigrati"),
            tooltip=["quartiere", alt.Tooltip("totale_emigrati:Q", format=",.0f")],
        )
        .properties(height=max(25 * len(emig), 120))
    )
    st.altair_chart(chart, width="stretch")

# ══════════════════════════════════════════════════════════════════════════════
# Indici di fragilità
# ══════════════════════════════════════════════════════════════════════════════

st.markdown("---")
st.subheader("🔍 Indici di fragilità per quartiere (2026)")

df_frag = load_mart("indici_fragilita", "mart_fragilita_quartiere", 2026)
if not df_frag.empty:
    display = df_frag[
        ["quartiere", "frag_demo_media", "frag_soc_media", "frag_econ_media", "frag_compl_media"]
    ].copy()
    display.columns = ["Quartiere", "Frag. Demografica", "Frag. Sociale", "Frag. Economica", "Frag. Complessiva"]
    st.dataframe(
        display.sort_values("Frag. Complessiva", ascending=False),
        column_config={
            "Frag. Demografica": st.column_config.NumberColumn(format="%.2f"),
            "Frag. Sociale": st.column_config.NumberColumn(format="%.2f"),
            "Frag. Economica": st.column_config.NumberColumn(format="%.2f"),
            "Frag. Complessiva": st.column_config.NumberColumn(format="%.2f"),
        },
        hide_index=True,
        width="stretch",
    )

st.caption("Fonte: OpenData Comune di Bologna — Popolazione, Famiglie, Emigrati, Indici fragilità · CC BY 4.0")
