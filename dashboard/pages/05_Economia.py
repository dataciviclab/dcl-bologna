"""Economia & Società — reddito mediano, esercizi commerciali."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, load_mart

st.title("💰 Reddito & Commercio")
st.markdown("Reddito mediano per area statistica e distribuzione esercizi commerciali.")

# ══════════════════════════════════════════════════════════════════════════════
# Reddito mediano per area
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("💶 Reddito imponibile mediano per area statistica")

df_reddito = load_mart("reddito_mediano", "mart_reddito_area", 2026)
anni_reddito = sorted(df_reddito["anno"].unique()) if not df_reddito.empty else []
anno_r = st.selectbox("Anno", anni_reddito, index=len(anni_reddito) - 1, key="eco_anno") if anni_reddito else None

if anno_r and not df_reddito.empty:
    df_r = df_reddito[df_reddito["anno"] == anno_r].copy()
    df_r = df_r.sort_values("reddito_imponibile_mediano", ascending=False)

    col_chart, col_table = st.columns([2, 1])
    with col_chart:
        chart = (
            alt.Chart(df_r.head(20))
            .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3, color="#10b981")
            .encode(
                y=alt.Y("area_statistica:N", title="", sort="-x"),
                x=alt.X("reddito_imponibile_mediano:Q", title="Reddito mediano (€)", axis=alt.Axis(format="~s")),
                tooltip=[
                    "area_statistica",
                    alt.Tooltip("reddito_imponibile_mediano:Q", title="Mediano €", format=",.0f"),
                    alt.Tooltip("numero_contribuenti:Q", title="Contribuenti", format=",.0f"),
                ],
            )
            .properties(height=max(22 * min(len(df_r), 20), 120))
        )
        st.altair_chart(chart, width="stretch")

    with col_table:
        st.metric("📊 Aree totali", len(df_r))
        mediana = df_r["reddito_imponibile_mediano"].median()
        st.metric("Mediana delle aree", f"€ {mediana:,.0f}")
        st.metric("Contribuenti totali", fmt_num(int(df_r["numero_contribuenti"].sum())))
else:
    st.info("Dati reddito non disponibili per l'anno selezionato.")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Esercizi commerciali per quartiere
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🏪 Esercizi commerciali per quartiere")

df_esercizi = load_mart("esercizi_somministrazione", "mart_esercizi_quartiere", 2026)
if not df_esercizi.empty:
    # filtra solo quartieri attuali
    attuali = df_esercizi[df_esercizi.get("quartiere_attuale", pd.Series([True] * len(df_esercizi)))]
    eser = attuali.groupby("quartiere", as_index=False).agg(n_esercizi=("n_esercizi", "sum"))
    eser = eser.sort_values("n_esercizi", ascending=False)

    chart = (
        alt.Chart(eser)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#f59e0b")
        .encode(
            y=alt.Y("quartiere:N", title="", sort="-x"),
            x=alt.X("n_esercizi:Q", title="N. esercizi"),
            tooltip=["quartiere", alt.Tooltip("n_esercizi:Q", format=",.0f")],
        )
        .properties(height=max(30 * len(eser), 180))
    )
    st.altair_chart(chart, width="stretch")

    # Stato esercizi
    st.markdown("**Stato esercizi**")
    by_stato = df_esercizi.groupby("stato", as_index=False).agg(n=("n_esercizi", "sum"))
    by_stato = by_stato.sort_values("n", ascending=False)
    chart2 = (
        alt.Chart(by_stato)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#8b5cf6")
        .encode(
            y=alt.Y("stato:N", title="", sort="-x"),
            x=alt.X("n:Q", title="N. esercizi"),
            tooltip=["stato", alt.Tooltip("n:Q", format=",.0f")],
        )
        .properties(height=150)
    )
    st.altair_chart(chart2, width="stretch")
else:
    st.info("Dati esercizi commerciali non disponibili.")

st.caption("Fonte: OpenData Comune di Bologna — Reddito imponibile, Esercizi somministrazione · CC BY 4.0")
