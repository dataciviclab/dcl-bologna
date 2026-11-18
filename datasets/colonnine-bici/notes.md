# notes.md — colonnine-bici

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **Export unico multi-anno**: a differenza di spire (un dataset ODS per anno), `colonnine-conta-bici` è un singolo parquet con 2018-2026. Quindi `dataset.years: [2026]` (run year) + `time_coverage` per la serie, e `anno` è **derivato** dalla data nel clean, non da `{year}`.
- **Righe duplicate**: ~60 coppie `(data, colonnina)` con letture ridondanti e valori diversi (es. `totale` 0 vs 51). Risolte nel clean con `QUALIFY ROW_NUMBER() ... ORDER BY totale DESC = 1` (tengo la lettura maggiore). Verificato: dopo dedup, `(data, colonnina)` è unica.
- **Timezone (verificato 2026-11-17)**: `data` è **ora locale** di Bologna, non UTC.
  Le etichette dell'export mentono (CSV `+00:00`, parquet `+01:00` fisso). Prova: il
  31/03/2024 il giorno ha 23 ore (manca la 01:xx) e il 15/06 ne ha 24 — in UTC sarebbero
  24 entrambi. Il picco bici alle 8 (non alle 6) lo conferma. Il clean non converte nulla.

## Rischi noti

- **Geografia**: niente più CSV di mapping. Il clean prende il **civico più vicino** dal support
  dataset `rifter-civici` (quarter/zona/area statistica/zona di prossimità) con haversine sulle
  coordinate estratte dal WKT (`CAST(geo_point_2d AS VARCHAR)`), senza estensione spatial.
  Verificato il 2026-11-18: 24/24 quartieri e 24/24 zone identici al vecchio mapping, distanza
  mediana dal civico 21 m (max 58 m). Il toolkit esegue il support prima del candidate
  (`skip-if-exists`) e risolve `{support.civici.clean}`: nessun ordine di batch da gestire.
- **Coordinate della colonnina**: vengono dal raw (`geo_point_2d` → WKT), non più dal mapping.
- **Copertura disomogenea**: la colonnina Ercolani è attiva dal 2018, le altre dal 2022/2024. `mart_colonnine_anno` con `rank_traffico_anno` confronta anni con numero di colonnine diverso — non è un bug ma va interpretato.

## Decisioni metodologiche

- **`source_id`**: `comune_bologna_opendata` placeholder — da registrare in source-observatory (stessa nota di spire-traffico).
- **Benchmark nel mart**: `rank_traffico_anno` (PERCENT_RANK) e `quota_pct_anno` seguono il pattern comuni/sintesi del candidate-standard.
- **Dedup scelta**: tenere la lettura con `totale` maggiore è conservativo (non inventa dati). Documentata per replicabilità.
