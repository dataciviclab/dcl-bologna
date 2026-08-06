# notes.md — spire-traffico

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`codice_spira` non è stabile**: il codice può cambiare nel tempo e due spire diverse possono condividere lo stesso codice nella stessa data (verificato: 730 righe duplicate su `(data, codice_spira)`). **Non usare `codice_spira` come chiave.**
- **Chiave stabile**: `id_uni` (841 spire, ognuna con 1 `nome_via` e 1 coppia lat/lon, verificato). Per l'unicità del clean serve anche `livello` (una spira può avere 2 livelli nella stessa data).
- **`chiave` (ID_univoco_stazione_spira)**: 840 valori, quasi stabile ma con duplicati su `(data, chiave, direzione)` risolti da `direzione` — non usato come PK.
- **Struttura wide**: 24 colonne `00_00_01_00`..`23_00_24_00` → serve UNPIVOT in clean.sql. È il primo dataset Bologna con vero lavoro di pulizia.
- **Geometria**: la colonna `geopoint` (GEOMETRY) è stata esclusa dal clean — tengo `longitudine`/`latitudine` come DOUBLE.

## Rischi noti

- **Dimensione**: UNPIVOT 24× amplifica il volume (304k wide → ~7,3M long/anno). Mart e query vanno dimensionati.
- **Copertura**: verificare quante spire sono attive per anno — alcune vie potrebbero mancare in anni specifici.
- **Famiglia incompleta**: 2022-2025 copre solo `rilevazione-flusso-*`. Gli anni 2019-2021 usano `rilevazione-autoveicoli-*` (schema probabilmente diverso) — vanno aggiunti con `url_suffix_by_year` o una seconda source.

## Decisioni metodologiche

- **`source_id`**: `comune_bologna_opendata` non è ancora in source-observatory. Da aprire un intake issue / source-check per la tracciabilità (campo obbligatorio a standard).
- **`primary_key` clean**: `(data, id_uni, livello, fascia_oraria)` — unico verificato empiricamente sul parquet 2025.
- **Benchmark nel mart**: `rank_passaggi_anno` in `mart_spire_sintesi` (PERCENT_RANK) segue il pattern comuni/sintesi/trend del candidate-standard.
- **POC**: 4 anni campione (2022-2025), non la serie completa — sufficiente per valutare il flusso toolkit.
