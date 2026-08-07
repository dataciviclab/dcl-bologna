# notes.md — incarichi

- Export unico multi-anno (2012-2026): `years: [2026]` (run year) + `time_coverage`.
- **Chiave**: `id` unico (750 righe = 750 id, verificato su export fresco). `n_pg_atto` NON è unico (181 duplicati).
- **`importo_euro` = 0** è un valore legittimo (incarichi senza corrispettivo dichiarato), non un errore → `not_null` ok, nessuna pulizia del valore.
- `anno` deriva da `anno_pg_atto` (DATE della protocollazione), non da `{year}`.
- `curriculum_link` può essere NULL — colonna informativa, non in `required_columns`.
- **Cross ANAC**: `mart_incarichi_soggetti` mantiene `partita_iva` per il join con ANAC (analisi 05, issue #8 di dcl-bologna).
- **`required_columns` completo (20/20)**: la check readiness `validation_rules_coverage` richiede ≥80% di colonne clean coperte. Con 20 colonne, un `required_columns` minimale fallisce la coverage → elencare tutte le colonne output (verifica solo presenza). `not_null` resta sulle chiavi.
- `source_id`: `comune_bologna_opendata` placeholder — da registrare in SO.
