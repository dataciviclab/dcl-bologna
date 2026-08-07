# notes.md — varchi-ztl

Quirk della fonte, rischi noti, decisioni metodologiche.

## Architettura (caso famiglia)

- **Il toolkit non ha un fan-out nativo**: una famiglia di N dataset non si modella come sorgente unica. Due strade possibili:
  - `raw.sources[]` esplicite + `read.mode: all` (pattern ga-\*: 31 source dichiarate) — standard ma 80 righe yml e N download.
  - **scelta adottata**: script di bootstrap a parte (`fetch_varchi_toolkit.py`) + `raw.type: local_file` sul mergiato. Perché: il merge dei 80 varchi è un'operazione da ~100s che NON va ripetuta a ogni run; `local_file` evita il re-run. Costo: non riproducibile da CI senza prima eseguire lo script (limite documentato, da risolvere in Fase 5 con un job CI dedicato).
- **`type: script` scartato**: il toolkit riesegue lo script a ogni run (solo `output_policy: overwrite|versioned`, niente skip). Su 18,6M righe il raw supera il timeout di 600s del toolkit. `local_file` risolve.

## Lezioni tecniche (D4 — imparate a caro prezzo)

- **MAI `duckdb.connect()` puro su dataset grandi**: bypassa il `memory_limit=2GB` che `lab_connectors.safe_connect` applica sempre. Su 20M righe → OOM che collassa il sistema (successo su macchina 5.8GB RAM).
- **`ROW_NUMBER() OVER (PARTITION BY ...)` su 18,6M righe → OOM** anche con `memory_limit=2GB` (failed to pin block). Il dedup per chiave con **`GROUP BY` + `max()` è ~26x più economico** (0.7s vs esplosione) e non usa window.
- **`SELECT DISTINCT *` ≠ dedup per chiave**: DISTINCT * ha dato 18,631,372 vs 18,630,531 del dedup su (data,varco) — 841 righe con stessa chiave ma colonne diverse (es. coordinate). Il dedup corretto è per chiave, non per riga intera.
- **Server ODS lento**: ~50s per generare export parquet di dataset grandi (spire 17MB, varchi). Non è la rete (misurato: 75MB/s). Il download dei 80 varchi è un costo da bootstrap, non da ogni run.

## Quirk della fonte

- **Doppioni nel merge**: ~3817 righe duplicate (stessa data+varco, valori identici o quasi) per sovrapposizione tra i 80 dataset ODS. Rimossi con dedup per chiave (0.02% su 18,6M).
- **Coordinate WKB**: il campo `coordinate` è GEOMETRY binaria (21 byte, POINT). DuckDB la casta a VARCHAR come `"POINT (lon lat)"` → regex per estrarre lon/lat. Il GEOMETRY→BLOB fallisce, il VARCHAR funziona.
- **`chiave` non stabile**: non usata come chiave (vedi colonnine). Chiave del clean: `(data, varco)`.
- **Timezone**: `data` è TIMESTAMP WITH TIME ZONE nell'export; il clean casta a TIMESTAMP.

## Rischi noti

- **Cache dei 80 varchi**: lo script usa `_data/varco-n-*.parquet` come cache di default (già presenti). In CI serve popolare la cache o eseguire lo script come step dedicato.
- **Path assoluto in dataset.yml**: `local_file` usa un path assoluto alla candidate root (convenzione locale POC). In produzione da rendere relativo o configurabile.
- **Famiglia incompleta**: 2019-2026 è la serie attuale; verificare che il catalogo non abbia aggiunto varchi dopo `catalog_full.json`.

## Decisioni metodologiche

- **`primary_key` clean**: `(data, varco)` — unica dopo dedup per chiave.
- **Dedup nello script di bootstrap** (`GROUP BY data, varco` nel merge): il raw prodotto è già dedup. Il `clean.sql` mantiene lo stesso GROUP BY come **guardia** riproducibile (costo 0.7s su 18,6M righe, nessun window → nessun OOM) — se il raw cambia, il clean garantisce comunque la chiave. Il "possessore" del dedup è lo script; il clean lo difende.
- **Benchmark nel mart**: `quota_pct` + `rank_varco` (PERCENT_RANK) seguono il pattern comuni/sintesi.
- **`source_id`**: `comune_bologna_opendata` placeholder — da registrare in SO (stessa nota degli altri candidate).
- **Portabilità**: il `dataset.yml` usa un path assoluto per il `local_file` (convenzione POC locale). Non riproducibile su altre macchine/CI senza prima generare il mergiato e aggiornare il path — da risolvere in Fase 5 (job CI dedicato + path relativo/configurabile).
