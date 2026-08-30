#!/usr/bin/env python3
"""
dcl-bologna · Dashboard Streamlit
Bologna in dati — 15 dataset, 6 temi, dal 1986 ad oggi.
"""

import streamlit as st

st.set_page_config(
    page_title="Bologna in Dati · Dashboard",
    page_icon="🏛️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Navigazione tematica
pages = {
    "": [
        st.Page("pages/01_Panoramica.py", title="Panoramica", icon="📊", default=True),
    ],
    "Demografia": [
        st.Page("pages/02_Demografia.py", title="Popolazione & Quartieri", icon="👥"),
    ],
    "Mobilità": [
        st.Page("pages/03_Mobilita.py", title="ZTL · Bici · Spire", icon="🚲"),
    ],
    "Ambiente": [
        st.Page("pages/04_Ambiente.py", title="Aria & Meteo", icon="🌿"),
    ],
    "Economia & Società": [
        st.Page("pages/05_Economia.py", title="Reddito & Commercio", icon="💰"),
    ],
    "PA & Trasparenza": [
        st.Page("pages/06_PA.py", title="Incarichi Comune", icon="🏛️"),
    ],
    "Esplora": [
        st.Page("pages/07_Quartieri.py", title="Quartieri (mappa)", icon="🗺️"),
        st.Page("pages/08_Query_SQL.py", title="Query SQL", icon="🧪"),
    ],
}

pg = st.navigation(pages, position="sidebar")

st.sidebar.markdown("---")
st.sidebar.caption("Dati: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) · CC BY 4.0")
st.sidebar.caption("Codice: [dataciviclab/dcl-bologna](https://github.com/dataciviclab/dcl-bologna)")
st.sidebar.caption("[DataCivicLab](https://dataciviclab.org/)")

pg.run()
