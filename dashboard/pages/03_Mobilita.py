"""Mobilità — ZTL, bici, spire, WiFi pedonale."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, load_mart

st.title("🚲 ZTL · Bici · Spire")
st.markdown("18,6 milioni di passaggi ai varchi ZTL, 27 colonnine bici, spire di traffico, flussi WiFi pedonali.")

# ══════════════════════════════════════════════════════════════════════════════
# KPI Mobilità
# ══════════════════════════════════════════════════════════════════════════════

df_varchi = load_mart("varchi_ztl", "mart_varchi_varco", 2026)
df_bici = load_mart("colonnine_bici", "mart_colonnine_anno", 2026)
df_spire = load_mart("spire_traffico", "mart_spire_sintesi", 2025)
df_wifi = load_mart("bolognawifi_matrice", "mart_wifi_anno", 2026)

k1, k2, k3, k4 = st.columns(4)
tot_ztl = int(df_varchi["totale_passaggi"].sum()) if not df_varchi.empty else 0
tot_bici = int(df_bici["totale_passaggi"].sum()) if not df_bici.empty else 0
tot_spire = int(df_spire["totale_passaggi"].sum()) if not df_spire.empty else 0
tot_wifi = int(df_wifi["flussi_totali"].sum()) if not df_wifi.empty else 0
k1.metric("🚗 Passaggi ZTL", fmt_num(tot_ztl), "2026")
k2.metric("🚲 Passaggi bici", fmt_num(tot_bici), "2026")
k3.metric("📡 Passaggi spire", fmt_num(tot_spire), "2025")
k4.metric("📶 Flussi WiFi", fmt_num(tot_wifi), "2026")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Profilo orario ZTL
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🚗 Profilo orario varchi ZTL (2026)")

df_ora = load_mart("varchi_ztl", "mart_varchi_ora", 2026)
if not df_ora.empty:
    chart = (
        alt.Chart(df_ora)
        .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3, color="#f59e0b")
        .encode(
            x=alt.X("ora_inizio:O", title="Ora"),
            y=alt.Y("totale_passaggi:Q", title="Media passaggi/ora", axis=alt.Axis(format="~s")),
            tooltip=[
                alt.Tooltip("ora_inizio:O", title="Ora"),
                alt.Tooltip("totale_passaggi:Q", title="Totale", format=",.0f"),
                alt.Tooltip("auto_furgoni:Q", title="Auto/Furgoni", format=",.0f"),
            ],
        )
        .properties(height=280)
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Dati profilo orario non disponibili.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Top varchi per passaggi
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🏆 Top 15 varchi per passaggi (2026)")

if not df_varchi.empty:
    top_v = df_varchi.nlargest(15, "totale_passaggi")
    chart = (
        alt.Chart(top_v)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#ef4444")
        .encode(
            y=alt.Y("nome_varco:N", title="", sort="-x"),
            x=alt.X("totale_passaggi:Q", title="Passaggi totali", axis=alt.Axis(format="~s")),
            tooltip=[
                "nome_varco",
                alt.Tooltip("totale_passaggi:Q", title="Totale", format=",.0f"),
                alt.Tooltip("passaggi_giorno_medi:Q", title="Media/giorno", format=",.0f"),
            ],
        )
        .properties(height=max(25 * len(top_v), 120))
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Dati varchi non disponibili.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Bici per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🚲 Colonnine bici per quartiere (2026)")

df_bici_q = load_mart("colonnine_bici", "mart_colonnine_quartiere", 2026)
if not df_bici_q.empty:
    bici_q = df_bici_q.sort_values("totale_passaggi", ascending=False)
    chart = (
        alt.Chart(bici_q)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#22c55e")
        .encode(
            y=alt.Y("quartiere:N", title="", sort="-x"),
            x=alt.X("totale_passaggi:Q", title="Passaggi totali", axis=alt.Axis(format="~s")),
            tooltip=[
                "quartiere",
                alt.Tooltip("totale_passaggi:Q", title="Totale", format=",.0f"),
                alt.Tooltip("bici_giorno_medi:Q", title="Media/giorno", format=",.0f"),
            ],
        )
        .properties(height=max(25 * len(bici_q), 120))
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Dati bici per quartiere non disponibili.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Trend spire di traffico
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("📈 Trend spire di traffico")

df_trend_spire = load_mart("spire_traffico", "mart_spire_trend", None)
if not df_trend_spire.empty:
    display = df_trend_spire[
        ["nome_via", "first_year", "last_year", "passaggi_giorno_primo_anno", "passaggi_giorno_ultimo_anno", "cagr_pct"]
    ].copy()
    display.columns = ["Via", "Dal", "Al", "Media/giorno (inizio)", "Media/giorno (fine)", "CAGR %"]
    st.dataframe(
        display.sort_values("CAGR %", ascending=False),
        column_config={
            "Media/giorno (inizio)": st.column_config.NumberColumn(format=",.0f"),
            "Media/giorno (fine)": st.column_config.NumberColumn(format=",.0f"),
            "CAGR %": st.column_config.NumberColumn(format="%.1f%%"),
        },
        hide_index=True,
        width="stretch",
        height=min(35 * len(display) + 35, 400),
    )
else:
    st.info("Dati trend spire non disponibili.")

st.caption("Fonte: OpenData Comune di Bologna — Varchi ZTL, Colonnine bici, Spire traffico, BolognaWiFi · CC BY 4.0")
