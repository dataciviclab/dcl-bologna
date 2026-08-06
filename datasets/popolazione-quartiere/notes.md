# notes.md — popolazione-quartiere

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`anno` è DATE nel parquet** (es. `1986-01-01`), non INTEGER. La issue #14 di dcl-bologna segnalava questo mismatch nel vecchio yml. Il clean lo deriva con `EXTRACT(YEAR FROM anno)` → INTEGER.
- **Export unico multi-anno** (1986-2024 in un file): `dataset.years: [2024]` (run year) + `time_coverage` per la serie, `anno` derivato dalla data (stesso pattern di colonnine-bici).
- **`eta_singolo` arriva fino a 112** (singoli anni di età). `eta_grandi` e `eta_quinquennali` sono classi derivate già presenti nel raw.

## Rischi noti

- **`centro_storico_zone_periferiche`**: include valori tipo "Centro Storico" / "Zone periferiche" — non confonderlo con una zona vera.
- **"Senza fissa dimora"**: compare come quartiere nei dati grezzi; nei mart è escluso con `quartiere <> ''` ma il valore resta nel clean. Da decidere se escluderlo nei mart finali.

## Decisioni metodologiche

- **`primary_key` clean**: `(anno, quartiere, zona, eta_singolo, sesso, cittadinanza)` — unico verificato empiricamente (239.075 righe = 239.075 chiavi).
- **Benchmark nel mart**: `indice_vecchiaia` (65+/0-14) e `rank_quartiere` seguono il pattern comuni/sintesi del candidate-standard.
- **`source_id`**: `comune_bologna_opendata` placeholder — da registrare in source-observatory (stessa nota di spire/colonnine).
