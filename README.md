# dcl-bologna — Bologna in dati

[![CI](https://github.com/dataciviclab/dcl-bologna/actions/workflows/ci.yml/badge.svg)](https://github.com/dataciviclab/dcl-bologna/actions/workflows/ci.yml)

**18,6 milioni di passaggi ai varchi ZTL, popolazione per quartiere dal 1986, qualità dell'aria, bici e mobilità. I dati aperti di Bologna, interrogabili.**

Primo progetto territoriale del DataCivicLab. Selezioniamo i migliori dataset
del portale [OpenData Bologna](https://opendata.comune.bologna.it) (702 dataset)
e li rendiamo interrogabili in locale via DuckDB, con la pipeline standard del Lab
([toolkit](https://github.com/dataciviclab/toolkit)).

## Perché Bologna

Bologna ha uno dei portali open data comunali più maturi d'Italia:
- **702 dataset**, licenza CC BY 4.0
- **Serie storiche** demografiche dal 1986
- **Dati di mobilità** (ZTL, bici, spire, parcheggi) con granularità oraria
- **Geolocalizzati** — coordinate, quartieri, zone
- **API pulita** con export diretto in Parquet

## Cosa contiene

Tutti i dataset sono configurati in `datasets/<slug>/` con lo standard candidate del Lab
(`dataset.yml` + `sql/clean.sql` + `sql/mart_*.sql`).

| Dataset | Records | Periodo | Freq |
|---|---|---|---|
| **Varchi ZTL** (80 accessi) | **18,6M** | 2019–2026 | mensile |
| Spire traffico (fuori ZTL) | 7,3M/anno | 2022–2025 | mensile |
| Colonnine conta-bici | 525k | 2018–2026 | mensile |
| Popolazione per quartiere | 239k | 1986–2024 | annuale |
| Centraline qualità aria | 46k | 2026 | daily |
| Temperature / Precipitazioni | 9,3k+9,3k | 2001–2026 | daily |
| Incarichi collaborazione | 750 | 2012–2026 | weekly |
| Emigrati per destinazione | 82k | 1986–2024 | annuale |
| Famiglie per tipologia | 78k | 1986–2024 | annuale |
| Popolazione in convivenza | 93k | 1986–2024 | annuale |

## Esempi di domande

- **Quante auto e quante bici passano per Viale Ercolani?** (~2.900 bici vs ~930 auto/giorno nei giorni rilevati 2024 — rapporto 3:1)
- **Come è cambiata la popolazione dei quartieri dal 1986?**
- **Quali varchi e quali vie hanno più traffico, e a che ora?**
- **C'è relazione tra traffico e inquinamento dell'aria?**
- **Quali zone della città sono più servite da colonnine bici?**

## Come accedere ai dati

### 1. Esegui la pipeline (toolkit)

```bash
# esegue raw → clean → mart per un dataset
toolkit run --config datasets/popolazione-quartiere/dataset.yml

# oppure via Makefile
make run/popolazione-quartiere
```

L'output è in `out/data/clean/<slug>/<anno>/` (parquet puliti) e
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

Le analisi SQL pronte sono in `analisi/` (es. `02_bici_vs_auto.sql`) e leggono dai
parquet clean in `out/data/clean/`.

## Partecipa

- **Hai una domanda su Bologna?** Apri una [Discussion](https://github.com/dataciviclab/dcl-bologna/discussions)
- **Vuoi proporre un dataset?** Apri un'issue col template [📥 Dataset](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Vuoi proporre un'analisi?** Apri un'issue col template [📄 Analisi](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Hai trovato un bug?** Apri un'issue col template [🐛 Bug](https://github.com/dataciviclab/dcl-bologna/issues/new/choose)
- **Vuoi contribuire?** Vedi [CONTRIBUTING.md](CONTRIBUTING.md) — se inizi, cerca le issue con label `good first issue`

## Roadmap

- [x] Scoring pilota 20/80 del portale (702 dataset) — catalogo statico ritirato, consultazione via API live
- [x] Popolazione per quartiere (1986–2024)
- [x] Colonnine bici + mapping quartieri
- [x] Varchi ZTL + mapping quartieri
- [x] Spire traffico (complemento ZTL)
- [x] Qualità aria + incrocio traffico/inquinamento
- [x] Demografia completa (emigrati, famiglie, convivenze)
- [x] Migrazione completa alla pipeline toolkit (Fase 5)
- [ ] Dashboard quartieri

## Architettura

```
datasets/<slug>/dataset.yml  →  toolkit run  →  out/data/{raw,clean,mart}/<slug>/
        │                                        │
        │  sql/clean.sql + mart_*.sql            ↓
        └────────────────────────────→  DuckDB / analisi SQL
mapping/*.csv  →  join territoriali (support file ADR-005)
```

Stack: [toolkit](https://github.com/dataciviclab/toolkit) (raw → clean → mart) + DuckDB.
Dipendenze: vedi `requirements.txt` (per il toolkit: workspace venv del Lab).

## Licenza

- **Codice**: MIT
- **Dati**: CC BY 4.0 (Comune di Bologna)
