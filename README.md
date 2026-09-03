# dcl-bologna — Bologna in dati

[![CI](https://github.com/dataciviclab/dcl-bologna/actions/workflows/ci.yml/badge.svg)](https://github.com/dataciviclab/dcl-bologna/actions/workflows/ci.yml)

**I dati aperti del Comune di Bologna, interrogabili in locale e visualizzabili in una dashboard interattiva.**

Primo progetto territoriale del DataCivicLab. Selezioniamo i migliori dataset
del portale [OpenData Bologna](https://opendata.comune.bologna.it) (702 dataset)
e li rendiamo interrogabili via DuckDB, con la pipeline standard del Lab
([toolkit](https://github.com/dataciviclab/toolkit)).

## Dashboard

Una [dashboard Streamlit](dashboard/) visualizza i dati per tema:

- **Popolazione e quartieri** — mappa interattiva, trend 1986–2024, indici di fragilità
- **Mobilità** — varchi ZTL, bici, spire traffico, WiFi pedonale, profili orari
- **Ambiente** — qualità aria (NO₂), temperature, precipitazioni
- **Economia** — reddito mediano per area statistica, esercizi commerciali
- **PA** — incarichi di collaborazione del Comune (trasparenza attiva)

```bash
cd dashboard && pip install -r requirements.txt && streamlit run app.py
```

## Perché Bologna

Bologna ha uno dei portali open data comunali più maturi d'Italia:
- **702 dataset**, licenza CC BY 4.0
- **Serie storiche** demografiche dal 1986
- **Dati di mobilità** (ZTL, bici, spire) con granularità oraria
- **Geolocalizzati** — coordinate, quartiere (6 circoscrizioni)
- **API pulita** con export diretto in Parquet

## Cosa contiene

15 dataset configurati in `datasets/<slug>/` con lo standard candidate del Lab
(`dataset.yml` + `sql/clean.sql` + `sql/mart_*.sql`).

| Dataset | Periodo | Tema |
|---|---|---|
| [Popolazione per quartiere](datasets/popolazione-quartiere/) | 1986–2024 | Demografia |
| [Famiglie per tipologia](datasets/famiglie-tipologia/) | 1986–2024 | Demografia |
| [Emigrati per destinazione](datasets/emigrati-destinazione/) | 1986–2024 | Demografia |
| [Convivenze](datasets/convivenze/) | 1986–2024 | Demografia |
| [Indici di fragilità](datasets/indici-fragilita/) | 2023–2026 | Demografia |
| [Varchi ZTL](datasets/varchi-ztl/) | 2019–2026 | Mobilità |
| [Colonnine bici](datasets/colonnine-bici/) | 2018–2026 | Mobilità |
| [Spire traffico](datasets/spire-traffico/) | 2022–2025 | Mobilità |
| [BolognaWiFi matrice](datasets/bolognawifi-matrice/) | 2021–2025 | Mobilità |
| [Centraline qualità aria](datasets/centraline-aria/) | 2026 | Ambiente |
| [Temperature](datasets/temperatura/) | 2001–2026 | Ambiente |
| [Precipitazioni](datasets/precipitazioni/) | 2001–2026 | Ambiente |
| [Reddito mediano](datasets/reddito-mediano/) | 2016–2024 | Economia |
| [Esercizi somministrazione](datasets/esercizi-somministrazione/) | 2026 | Economia |
| [Incarichi collaborazione](datasets/incarichi/) | 2012–2026 | PA |

## Come accedere ai dati

### 1. Esegui la pipeline (toolkit)

```bash
# esegue raw → clean → mart per un dataset
make run/popolazione-quartiere

# tutti i dataset
make run-all
```

L'output è in `out/data/clean/<slug>/` (parquet puliti) e
`out/data/mart/<slug>/` (aggregazioni pronte).

### 2. Interroga i parquet con DuckDB

```python
import duckdb
duckdb.sql("""
    SELECT quartiere, SUM(residenti) AS residenti
    FROM read_parquet('out/data/clean/popolazione_quartiere/2024/popolazione_quartiere_2024_clean.parquet')
    WHERE anno = 2024
    GROUP BY quartiere ORDER BY residenti DESC
""").show()
```

### 3. Via analisi già pronte

Le analisi SQL sono in `analisi/` e leggono dai parquet clean.

## Partecipa

- **Hai una domanda su Bologna?** Apri una [Discussion](https://github.com/dataciviclab/dcl-bologna/discussions)
- **Vuoi proporre un dataset?** Apri un'issue col template [📥 Dataset](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Vuoi proporre un'analisi?** Apri un'issue col template [📄 Analisi](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Hai trovato un bug?** Apri un'issue col template [🐛 Bug](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Vuoi contribuire?** Vedi [CONTRIBUTING.md](CONTRIBUTING.md) — se inizi, cerca le issue con label `good first issue`

## Roadmap

- [x] Scoring pilota del portale (702 dataset)
- [x] 15 dataset attivi con pipeline toolkit
- [x] Dashboard Streamlit (mappa quartieri, KPI per tema, SQL explorer)

## Architettura

```
datasets/<slug>/dataset.yml  →  toolkit run  →  out/data/{raw,clean,mart}/<slug>/
        │                                        │
        │  sql/clean.sql + mart_*.sql            ↓
        └────────────────────→  DuckDB / analisi SQL / Dashboard Streamlit
mapping/*.csv  →  join territoriali (support file)
```

Stack: [toolkit](https://github.com/dataciviclab/toolkit) + DuckDB + Streamlit.

## Licenza

- **Codice**: MIT
- **Dati**: CC BY 4.0 (Comune di Bologna)
