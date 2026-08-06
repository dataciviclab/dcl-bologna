# notes.md — centraline-aria

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **Collisioni cambio ora legale**: 9 coppie duplicate su `(reftime, stazione, agente_atm)` nell'ora 02:00 del 2026-03-29, con valori reali diversi (es. O3 54 vs 57). Risolte nel clean con `QUALIFY ROW_NUMBER() ... ORDER BY value DESC = 1` (tengo il valore maggiore, stessa strategia di colonnine-bici).
- **`id` non è unico** nel raw (46.319 id distinti su 46.397 righe) — non usato come chiave.
- **`stazione` include il comune**: "GIARDINI MARGHERITA, BOLOGNA VIALE BOTTONELLI" — il clean non lo tronca (il valore completo è informativo).
- **Timezone**: `reftime` è `TIMESTAMP WITH TIME ZONE` nell'export; il clean casta a `TIMESTAMP`.

## Rischi noti

- **Serie storica**: il candidate copre 2025-2026 (dataset `centraline-qualita-aria`). La serie lunga è in `dati-centraline-bologna-storico` (da valutare come secondo source o candidate separato).
- **Soglie**: il `pct_sopra_soglia` usa soglie di riferimento (PM10>50, NO2>40, O3>120) — sono indicative, non normative.

## Decisioni metodologiche

- **`primary_key` clean**: `(reftime, stazione, agente_atm)` — unica dopo dedup.
- **`source_id`**: `comune_bologna_opendata` placeholder — da registrare in source-observatory.
