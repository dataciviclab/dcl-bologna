"""Ambiente — qualità dell'aria, temperature, precipitazioni."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import load_mart

st.title("🌿 Aria & Meteo")
st.markdown("Qualità dell'aria (NO₂), temperature e precipitazioni a Bologna.")

# ══════════════════════════════════════════════════════════════════════════════
# Qualità aria — media per stazione
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🌬️ NO₂ medio per stazione (2026)")

df_aria = load_mart("centraline_aria", "mart_aria_stazione", 2026)
if not df_aria.empty:
    # solo NO2
    no2 = df_aria[df_aria["agente_atm"].str.contains("NO2", case=False, na=False)].copy()
    if not no2.empty:
        chart = (
            alt.Chart(no2)
            .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#06b6d4")
            .encode(
                y=alt.Y("stazione:N", title="", sort="-x"),
                x=alt.X("media_valore:Q", title="NO₂ medio (µg/m³)"),
                tooltip=[
                    "stazione",
                    alt.Tooltip("media_valore:Q", title="Media", format=",.1f"),
                    alt.Tooltip("max_valore:Q", title="Max", format=",.1f"),
                    alt.Tooltip("pct_sopra_soglia:Q", title="% sopra soglia", format=".1f%%"),
                ],
            )
            .properties(height=max(30 * len(no2), 150))
        )
        st.altair_chart(chart, width="stretch")
    else:
        st.info("Dati NO₂ non disponibili per il 2026.")
else:
    st.info("Dati qualità aria non disponibili.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Profilo orario NO₂
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("⏰ Profilo orario NO₂ (2026)")

df_ora_aria = load_mart("centraline_aria", "mart_aria_ora", 2026)
if not df_ora_aria.empty:
    no2_ora = df_ora_aria[df_ora_aria["agente_atm"].str.contains("NO2", case=False, na=False)].copy()
    if not no2_ora.empty:
        # media su tutte le stazioni
        agg = no2_ora.groupby("ora_inizio", as_index=False).agg(media=("media_valore", "mean"))
        chart = (
            alt.Chart(agg)
            .mark_line(point=True, color="#06b6d4", strokeWidth=2.5)
            .encode(
                x=alt.X("ora_inizio:O", title="Ora"),
                y=alt.Y("media:Q", title="NO₂ medio (µg/m³)", scale={"zero": True}),
                tooltip=[alt.Tooltip("ora_inizio:O", title="Ora"), alt.Tooltip("media:Q", format=",.1f")],
            )
            .properties(height=250)
        )
        st.altair_chart(chart, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Trend temperature annuali
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🌡️ Temperature annuali")

df_temp = load_mart("temperature_bologna", "mart_temperatura_anno", 2026)
if not df_temp.empty:
    temp_sorted = df_temp.sort_values("anno")
    chart = (
        alt.Chart(temp_sorted)
        .mark_line(point=True, strokeWidth=2)
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("avg_media:Q", title="Media annua (°C)", scale={"zero": False}),
            color=alt.value("#ef4444"),
            tooltip=[
                "anno",
                alt.Tooltip("avg_media:Q", title="Media", format=",.1f"),
                alt.Tooltip("max_max:Q", title="Max", format=",.1f"),
                alt.Tooltip("min_min:Q", title="Min", format=",.1f"),
            ],
        )
        .properties(height=280)
    )
    st.altair_chart(chart, width="stretch")

    # Giorni oltre 35°C e giorni di gelo
    col_t1, col_t2 = st.columns(2)
    with col_t1:
        hot = temp_sorted[["anno", "giorni_oltre_35"]].dropna()
        if not hot.empty:
            st.metric("🔥 Giorni > 35°C (ultimi)", f"{int(hot['giorni_oltre_35'].iloc[-1])}", f"{int(hot['anno'].iloc[-1])}")
    with col_t2:
        cold = temp_sorted[["anno", "giorni_gelo"]].dropna()
        if not cold.empty:
            st.metric("❄️ Giorni di gelo (ultimi)", f"{int(cold['giorni_gelo'].iloc[-1])}", f"{int(cold['anno'].iloc[-1])}")
else:
    st.info("Dati temperature non disponibili.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Precipitazioni annuali
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🌧️ Precipitazioni annuali")

df_pioggia = load_mart("precipitazioni_bologna", "mart_precipitazioni_anno", 2026)
if not df_pioggia.empty:
    pioggia = df_pioggia.sort_values("anno")
    chart = (
        alt.Chart(pioggia)
        .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3, color="#3b82f6")
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("pioggia_totale_mm:Q", title="Precipitazioni (mm)"),
            tooltip=[
                "anno",
                alt.Tooltip("pioggia_totale_mm:Q", title="Totale mm", format=",.0f"),
                alt.Tooltip("giorni_pioggia:Q", title="Giorni pioggia", format=",.0f"),
                alt.Tooltip("max_giornaliero_mm:Q", title="Max giornaliero mm", format=",.1f"),
            ],
        )
        .properties(height=280)
    )
    st.altair_chart(chart, width="stretch")
else:
    st.info("Dati precipitazioni non disponibili.")

st.caption("Fonte: OpenData Comune di Bologna — Centraline aria ARPAE, Rete meteo · CC BY 4.0")
