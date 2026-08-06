# notes.md — colonnine-bici

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **Export unico multi-anno**: a differenza di spire (un dataset ODS per anno), `colonnine-conta-bici` è un singolo parquet con 2018-2026. Quindi `dataset.years: [2026]` (run year) + `time_coverage` per la serie, e `anno` è **derivato** dalla data nel clean, non da `{year}`.
- **Righe duplicate**: ~60 coppie `(data, colonnina)` con letture ridondanti e valori diversi (es. `totale` 0 vs 51). Risolte nel clean con `QUALIFY ROW_NUMBER() ... ORDER BY totale DESC = 1` (tengo la lettura maggiore). Verificato: dopo dedup, `(data, colonnina)` è unica.
- **Timezone**: il parquet ODS ha `data` come `TIMESTAMP WITH TIME ZONE` (sembra Atlantic/Canary nell'export). Il clean casta a `TIMESTAMP` — da verificare l'ora italiana nel consumo reale.

## Rischi noti

- **Join mapping**: il clean usa `read_csv('mapping/colonnine-quartieri.csv')` con path **relativo alla cwd di esecuzione** (root del repo, pattern eurostat con i codelists). Se il run parte da altrove, il path va aggiornato.
- **Copertura disomogenea**: la colonnina Ercolani è attiva dal 2018, le altre dal 2022/2024. `mart_colonnine_anno` con `rank_traffico_anno` confronta anni con numero di colonnine diverso — non è un bug ma va interpretato.

## Decisioni metodologiche

- **`source_id`**: `comune_bologna_opendata` placeholder — da registrare in source-observatory (stessa nota di spire-traffico).
- **Benchmark nel mart**: `rank_traffico_anno` (PERCENT_RANK) e `quota_pct_anno` seguono il pattern comuni/sintesi del candidate-standard.
- **Dedup scelta**: tenere la lettura con `totale` maggiore è conservativo (non inventa dati). Documentata per replicabilità.
