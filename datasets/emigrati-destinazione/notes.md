# notes.md — emigrati-destinazione

- Export unico multi-anno (1986-2024): `years: [2024]` + `time_coverage`.
- **Chiave**: `(anno, destinazione_comuni_regioni, quartiere, zona, sesso)` unica verificata.
  Nota: la colonna dettagliata `destinazione_comuni_e_aree_italia` NON è unica con la stessa
  combinazione (15.441 duplicati) — usare `destinazione_comuni_regioni` come chiave.
- `source_id`: `comune_bologna_opendata` placeholder — da registrare in SO.
