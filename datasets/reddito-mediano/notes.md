# notes.md — reddito-mediano

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`anno` è DATE** nel parquet (es. `2024-01-01`), non INTEGER — stesso quirk di popolazione-quartiere. Il clean deriva l'anno con `EXTRACT(YEAR FROM anno)`.
- **Nomi colonna raw lunghissimi** (`reddito_imponibile_mediano_dei_contribuenti_residenti`) → alias corti nel clean (`reddito_imponibile_mediano`).
- **`SENZA FISSA DIMORA`** è un'area del dataset (8022 € nel 2024, 369 contribuenti) — non è un'area territoriale. Da trattare con cautela o escludere dalle analisi territoriali.

## Rischi noti

- **Aree minuscole distorcono il ranking**: alcune aree hanno pochissimi contribuenti (Via del Genio: 11, Scalo Merci San Donato: 36) con redditi estremi (30k+). Per i confronti significativi usare **filtro su numero_contribuenti** (≥ 500 o ≥ 1000).
- **La variazione di reddito può riflettere il ricambio demografico, non l'impoverimento**: se una zona perde/acquista contribuenti (es. Roveri: 423 → 1.035 contribuenti mentre il reddito mediano crolla da 20.136 a 12.994 €), la composizione della popolazione è cambiata. **Leggere SEMPRE reddito e contribuenti insieme** — il reddito mediano da solo è ambiguo.
- **Serie corta per trend lunghi**: 9 anni (2016-2024) — sufficiente per tendenze di medio periodo, non per cicli completi.
- **Fonte non ancora in source-observatory**: `source_id: comune_bologna_opendata` placeholder condiviso con gli altri dataset del repo.

## Decisioni metodologiche

- **`primary_key` clean**: `(anno, area_statistica)` — verificata empiricamente (817 righe = 817 chiavi).
- **`anno` derivato da `anno` DATE** (multi-anno, `{year}` è solo il run year).
- **Niente normalizzazione monetaria**: i valori sono in euro correnti. Per confronti nominali anno-anno è ok (l'inflazione non è corretta — dichiarare se si usa "crescita nominale").
- **Rank nel mart**: `PERCENT_RANK` per area rispetto al comune, per anno — utile per "dove sta il top/bottom del reddito".
- **Join con fragilità**: l'area `area_statistica` è la stessa di `indici-fragilita` — il join cross-dataset è il valore aggiunto di questo candidate.
