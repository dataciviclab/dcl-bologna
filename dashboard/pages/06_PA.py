"""PA & Trasparenza — incarichi di collaborazione del Comune."""

import altair as alt
import pandas as pd
import streamlit as st

from sources import fmt_num, load_mart

st.title("🏛️ Incarichi Comune di Bologna")
st.markdown("Incarichi di collaborazione 2012–2026 — trasparenza attiva.")

# ══════════════════════════════════════════════════════════════════════════════
# KPI
# ══════════════════════════════════════════════════════════════════════════════

df_tipo = load_mart("incarichi", "mart_incarichi_tipo", 2026)
df_anno = load_mart("incarichi", "mart_incarichi_anno", 2026)

tot_incarichi = int(df_tipo["numero_incarichi"].sum()) if not df_tipo.empty else 0
n_tipi = len(df_tipo) if not df_tipo.empty else 0

k1, k2, k3 = st.columns(3)
k1.metric("📋 Incarichi (2026)", tot_incarichi)
k2.metric("🏷️ Tipi incarico", n_tipi)
k3.metric("📊 Anni coperti", len(df_anno) if not df_anno.empty else "—")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Trend annuale incarichi
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("📈 Trend incarichi per anno")

if not df_anno.empty:
    df_a = df_anno.sort_values("anno")
    chart = (
        alt.Chart(df_a)
        .mark_line(point=True, color="#3b82f6", strokeWidth=2.5)
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("numero_incarichi:Q", title="N. incarichi"),
            tooltip=[
                "anno",
                alt.Tooltip("numero_incarichi:Q", title="Incarichi"),
                alt.Tooltip("importo_totale:Q", title="Importo totale €", format=",.0f"),
            ],
        )
        .properties(height=280)
    )
    st.altair_chart(chart, width="stretch")

    # Importo totale per anno
    chart2 = (
        alt.Chart(df_a)
        .mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3, color="#10b981")
        .encode(
            x=alt.X("anno:O", title="Anno"),
            y=alt.Y("importo_totale:Q", title="Importo totale (€)", axis=alt.Axis(format="~s")),
            tooltip=[
                "anno",
                alt.Tooltip("importo_totale:Q", title="Importo totale €", format=",.0f"),
            ],
        )
        .properties(height=250)
    )
    st.altair_chart(chart2, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Distribuzione per tipo
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🏷️ Distribuzione per tipo incarico")

if not df_tipo.empty:
    tipo = df_tipo.sort_values("quota_incarichi_pct", ascending=False)
    chart = (
        alt.Chart(tipo)
        .mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4, color="#f59e0b")
        .encode(
            y=alt.Y("classificazione_incarichi:N", title="", sort="-x"),
            x=alt.X("quota_incarichi_pct:Q", title="% incarichi", axis=alt.Axis(format=".1f%%")),
            tooltip=[
                "classificazione_incarichi",
                alt.Tooltip("quota_incarichi_pct:Q", title="% incarichi", format=".1f%%"),
                alt.Tooltip("quota_importo_pct:Q", title="% importo", format=".1f%%"),
            ],
        )
        .properties(height=max(30 * len(tipo), 150))
    )
    st.altair_chart(chart, width="stretch")

st.markdown("---")

# ══════════════════════════════════════════════════════════════════════════════
# Top soggetti
# ══════════════════════════════════════════════════════════════════════════════

st.subheader("🏢 Top soggetti per importo (2026)")

df_soggetti = load_mart("incarichi", "mart_incarichi_soggetti", 2026)
if not df_soggetti.empty:
    top_s = df_soggetti.nlargest(15, "importo_totale")
    display = top_s[["ragione_sociale", "numero_incarichi", "importo_totale", "importo_medio"]].copy()
    display.columns = ["Soggetto", "N. incarichi", "Importo totale €", "Importo medio €"]
    st.dataframe(
        display,
        column_config={
            "Importo totale €": st.column_config.NumberColumn(format="€%,.0f"),
            "Importo medio €": st.column_config.NumberColumn(format="€%,.0f"),
        },
        hide_index=True,
        width="stretch",
        height=min(35 * len(display) + 35, 500),
    )

st.caption("Fonte: OpenData Comune di Bologna — Incarichi di collaborazione · CC BY 4.0")
