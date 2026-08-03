# dcl-bologna — Bologna in dati

**18,6 milioni di passaggi ai varchi ZTL, popolazione per quartiere dal 1986, qualità dell'aria, bici e mobilità. I dati aperti di Bologna, interrogabili.**

Primo progetto territoriale del DataCivicLab. Selezioniamo i migliori dataset
del portale [OpenData Bologna](https://opendata.comune.bologna.it) (702 dataset)
e li rendiamo interrogabili in locale via DuckDB.

## Perché Bologna

Bologna ha uno dei portali open data comunali più maturi d'Italia:
- **702 dataset**, licenza CC BY 4.0
- **Serie storiche** demografiche dal 1986
- **Dati di mobilità** (ZTL, bici, parcheggi) con granularità oraria
- **Geolocalizzati** — coordinate, quartieri, zone
- **API pulita** con export diretto in Parquet

## Cosa contiene

| Dataset | Records | Periodo | Freq |
|---|---|---|---|
| **Varchi ZTL** (80 accessi) | **18,6M** | 2019–2026 | mensile |
| Colonnine conta-bici | 516k | 2018–2026 | mensile |
| Varco ZTL Ercolani | 254k | 2019–2026 | mensile |
| Popolazione per quartiere | 239k | 1986–2024 | annuale |
| Centraline qualità aria | 44k | 2026 | daily |
| Riferimenti civici | 77k | — | mensile |
| Temperature / Precipitazioni | 9,3k+9,3k | 2001–2026 | daily |
| Incarichi collaborazione | 747 | 2012–2026 | weekly |

## Esempi di domande

- **Quante auto e quante bici passano per Viale Ercolani?** (~2.900 bici vs ~720 auto/giorno nel 2024)
- **Come è cambiata la popolazione dei quartieri dal 1986?**
- **Quali quartieri hanno più passaggi ZTL?**
- **C'è relazione tra traffico e inquinamento dell'aria?**
- **Quali zone della città sono più servite da colonnine bici?**

## Tre modi per accedere ai dati

### 1. Via DuckDB (locale)

```bash
pip install -r requirements.txt
make fetch
make q/popolazione-quartiere CMD="SELECT quartiere, sum(residenti) FROM data WHERE anno='2024-01-01' GROUP BY quartiere"
```

### 2. Via SQL ad hoc

Ogni dataset è interrogabile con DuckDB:

```python
import duckdb
duckdb.sql("""
    SELECT quartiere, SUM(residenti) AS residenti
    FROM read_parquet('_data/popolazione-quartiere.parquet')
    WHERE anno = '2024-01-01'
    GROUP BY quartiere ORDER BY residenti DESC
""").show()
```

### 3. Via analisi già pronte

Le analisi SQL pronte sono in `analisi/` (es. `02_bici_vs_auto.sql`).

## Partecipa

- **Hai una domanda su Bologna?** Apri una [Discussion](https://github.com/dataciviclab/dcl-bologna/discussions)
- **Vuoi proporre un dataset?** Segnalalo nelle discussioni
- **Vuoi contribuire?** Vedi [come contribuire al Lab](https://github.com/dataciviclab/dataciviclab/blob/main/docs/come-contribuire.md)

## Roadmap

- [x] Scoring 20/80 del catalogo (702 dataset)
- [x] Popolazione per quartiere (1986–2024)
- [x] Colonnine bici + mapping quartieri
- [x] Varchi ZTL + mapping quartieri
- [x] Qualità aria + incrocio traffico/inquinamento
- [ ] Demografia completa (emigrati, famiglie, convivenze)
- [ ] Dashboard quartieri

## Architettura

```
dataset/*.yml  →  pipeline/fetch.py  →  _data/*.parquet  →  DuckDB
                                                              ↓
mapping/*.csv  →  join territoriali  ←  analisi SQL
```

Repo autonomo, formati compatibili con il Lab. Dipendenze minime: duckdb, PyYAML, pandas.

## Licenza

- **Codice**: MIT
- **Dati**: CC BY 4.0 (Comune di Bologna)
