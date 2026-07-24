# dcl-bologna

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Primo progetto territoriale del **DataCivicLab**. Analisi dei dati aperti del Comune di Bologna.

> **Stato**: pilota attivo — 6 dataset, 19M records, 3 mapping territoriali.

## Cosa

Dati aperti di Bologna scaricati, strutturati e incrociati. Il portale [OpenData Bologna](https://opendata.comune.bologna.it) ha 702 dataset. Qui ne selezioniamo i migliori e li rendiamo interrogabili in locale via DuckDB.

## Perché

Bologna ha uno dei portali open data comunali più maturi d'Italia:
- **702 dataset**, licenza CC BY 4.0
- **Serie storiche** demografiche dal 1986
- **Dati di mobilità** (ZTL, bici, parcheggi) con granularità oraria
- **Geolocalizzati** — coordinate, quartieri, zone
- **API pulita** con export diretto in Parquet

## Dataset attivi

| Dataset | Records | Periodo | Freq |
|---|---|---|---|---|
| **Varchi ZTL** (80 accessi) | **18.6M** | 2019–2026 | mensile |
| Centraline qualità aria | 44k | 2026 | **daily** |
| Popolazione per quartiere | 239k | 1986–2024 | annuale |
| Colonnine conta-bici | 516k | 2018–2026 | mensile |
| Varco ZTL Ercolani | 254k | 2019–2026 | mensile |
| Rifter civici (indirizzi + quartiere) | 77k | — | mensile |

## Come si usa

```bash
# Stato
make status

# Scarica/aggiorna dati
make fetch
make fetch/popolazione-quartiere

# Query SQL
make q/popolazione-quartiere CMD="SELECT quartiere, sum(residenti) FROM data WHERE anno='2024-01-01' GROUP BY quartiere"

# Check completo
make check
```

## Cosa si può fare con questi dati

- **Bici vs Auto**: confronto su Viale Ercolani nel 2024: ~2.900 bici e ~720 auto/giorno (dati osservati, varco n.44 vs colonnina Ercolani — vedi `analisi/02_bici_vs_auto.sql`)
- **Demografia per quartiere**: popolazione 1986–2024, età, sesso, cittadinanza
- **Mobilità × territorio**: colonnine e varchi ZTL mappati ai quartieri via civici ufficiali
- **Cross-dominio**: incroci con dati nazionali Lab (ANAC, ISTAT, qualità aria)

## Architettura

```
dataset/*.yml  →  pipeline/fetch.py  →  _data/*.parquet  →  DuckDB
                                                              ↓
mapping/*.csv  →  join territoriali  ←  analisi SQL
```

Repo autonomo, formati compatibili con il Lab. Dipendenze minime: `pip install -r requirements.txt` (duckdb, PyYAML, pandas).

## Roadmap

- [x] Scoring 20/80 del catalogo (702 dataset)
- [x] Popolazione per quartiere (serie 1986–2024)
- [x] Colonnine bici + mapping ai quartieri
- [x] Varchi ZTL (80 accessi mergiati) + mapping ai quartieri
- [x] Pipeline fetch + validazione + registry
- [x] Qualità aria (NO2, PM10) + incrocio traffico/inquinamento
- [ ] Demografia completa (emigrati, famiglie, convivenze)
- [ ] Dashboard quartieri

## Licenza

- **Codice**: MIT ([LICENSE](./LICENSE))
- **Dati**: CC BY 4.0 (Comune di Bologna) — i dati originali restano di proprietà del Comune di Bologna e vengono redistribuiti nei termini della licenza CC BY 4.0 indicata sul portale.
