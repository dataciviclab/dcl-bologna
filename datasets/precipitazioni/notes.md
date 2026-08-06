# notes.md — precipitazioni

- Export unico multi-anno (2001-2026): `years: [2026]` (run year) + `time_coverage`.
- La colonna raw si chiama `184_avg_d` (id ODS del campo) → rinominata `pioggia_mm` nel clean.
- `date` unica → `primary_key: [date]`.
- `source_id`: `comune_bologna_opendata` placeholder — da registrare in SO.
