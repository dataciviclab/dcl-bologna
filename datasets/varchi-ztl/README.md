# varchi-ztl — passaggi veicolari dai 80 varchi ZTL

**Domanda civica**: quanto traffico entra ed esce dal centro di Bologna? Quali varchi sono i più carichi e in quali ore?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Trasporti
- **Famiglia**: 80 dataset `varco-n-*` (uno per accesso ZTL), unificati in un unico parquet
- **Granularità**: varco × data (oraria) — 1 riga = 1 varco × 1 ora
- **Periodo**: 2019–2026 (18,6M righe, 158MB mergiato)
- **Classificazione**: auto/furgoni, moto/ciclomotori, bus/camion, non classificato, liste (bianca/nera/speciale)

## Architettura

Il caso varchi è una **famiglia di 80 dataset** che il toolkit non modella nativamente (niente fan-out). Soluzione:

```
fetch_varchi_toolkit.py  →  varchi_ztl.parquet  (merge + dedup + decodifica WKB)
        │                                            │
        │ bootstrap (a parte)                        │
        ▼                                            ▼
  dataset.yml raw: local_file  →  out/data/raw/  →  clean.sql  →  mart
```

- **`fetch_varchi_toolkit.py`**: script di bootstrap eseguito a parte. Scarica i 80 varchi in cache, li unisce, decodifica le coordinate WKB → lon/lat DOUBLE, deduplica per chiave. Output: `varchi_ztl.parquet` nella candidate root.
- **`dataset.yml` raw**: `type: local_file` legge il mergiato (il toolkit NON riesegue lo script a ogni run — sarebbe ~100s+ per 18,6M righe).
- **`clean.sql`**: anno derivato + typing + dedup per chiave con GROUP BY.

## Struttura

```
datasets/varchi-ztl/
├── dataset.yml
├── fetch_varchi_toolkit.py      # bootstrap: merge 80 varchi + WKB + dedup
├── sql/
│   ├── clean.sql                # anno + typing + dedup GROUP BY
│   ├── mart_varchi_ora.sql      # profilo orario aggregato
│   └── mart_varchi_varco.sql    # per varco × anno + benchmark rank
├── README.md
└── notes.md
```

## Run

```bash
# 1. Bootstrap (una tantum, ~2 min): genera varchi_ztl.parquet
python datasets/varchi-ztl/fetch_varchi_toolkit.py --fetch

# 2. Pipeline toolkit (raw veloce, clean ~70s)
toolkit run --years 2026 --config datasets/varchi-ztl/dataset.yml
```

## Output minimo atteso

- `mart_varchi_ora`: picchi orari del traffico ZTL (8-9 e 17-19)
- `mart_varchi_varco`: varchi più carichi, quota, rank — confrontabile con spire (auto fuori ZTL) e colonnine (bici)

## Stato / prossimo passo

Fase 3 del piano di migrazione dcl-bologna → toolkit. Branch `feat/varchi-toolkit`.
