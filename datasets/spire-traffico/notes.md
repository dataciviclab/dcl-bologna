# notes.md — spire-traffico

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`codice_spira` non è stabile**: il codice può cambiare nel tempo e due spire diverse possono condividere lo stesso codice nella stessa data (verificato: 730 righe duplicate su `(data, codice_spira)`). **Non usare `codice_spira` come chiave.**
- **Chiave stabile**: `id_uni` (841 spire, ognuna con 1 `nome_via` e 1 coppia lat/lon, verificato). Per l'unicità del clean serve anche `livello` (una spira può avere 2 livelli nella stessa data).
- **`chiave` (ID_univoco_stazione_spira)**: 840 valori, quasi stabile ma con duplicati su `(data, chiave, direzione)` risolti da `direzione` — non usato come PK.
- **Struttura wide**: 24 colonne `00_00_01_00`..`23_00_24_00` → serve UNPIVOT in clean.sql. È il primo dataset Bologna con vero lavoro di pulizia.
- **Geometria**: la colonna `geopoint` (GEOMETRY) è stata esclusa dal clean — tengo `longitudine`/`latitudine` come DOUBLE.
- **⚠️ 2026 — 52 spire senza registro**: 15.100 righe del raw wide (una per spira-giorno), che nel clean long diventano **362.400**, arrivano con `id_uni`, `codice`, `codice_arco` NULL e in gran parte anche `livello`/`tipologia` NULL. Sono 52 `chiave` su 33 vie e valgono il **5,57% dei passaggi 2026** (64.443.265). Non esistono in nessun anno precedente (spire nuove), quindi non c'è backfill possibile da anni noti. Non è un problema dell'export: gli stessi NULL si vedono sull'API `records`. Le 52 spire **producono traffico** (tutte hanno ore >0; 4.680 spira-giorno su 15.100 sono interamente a zero), quindi scartarle perderebbe quei passaggi. **Segnalazione al Comune da fare** (non ancora aperta).

## Rischi noti

- **Dimensione**: UNPIVOT 24× amplifica il volume (304k wide → ~7,3M long/anno). Mart e query vanno dimensionati.
- **Copertura**: verificare quante spire sono attive per anno — alcune vie potrebbero mancare in anni specifici.
- **Famiglia incompleta**: 2022-2026 copre solo `rilevazione-flusso-*`. Gli anni 2019-2021 usano `rilevazione-autoveicoli-*` (schema probabilmente diverso) — vanno aggiunti con `url_suffix_by_year` o una seconda source.

## Decisioni metodologiche

- **CAGR normalizzato su passaggi/giorno** (non sui totali annuali): il totale annuo distorce la copertura parziale del primo/ultimo anno (es. VIA VITTORIO BIGARI attivata a luglio 2022 → 181/365 giorni → totale tagliato → CAGR gonfiato a +538%). Con la media/giorno scende a +405% e la copertura (181 vs 365 giorni) è esposta nel mart per il consumer. Vie con `giorni_rilevati_primo_anno` bassi vanno interpretate con cautela.
- **UNPIVOT → transizione `-2300%` righe**: la transizione raw→clean mostra `-2300%` (304k wide → 7,3M long, 24×) e il validatore la segnala (`qs=95`) ma `status` resta `passed`. È il comportamento atteso dell'UNPIVOT, non un errore. Readiness: `ready (8/8)` dopo `required_columns` completo (16/16) per la check `validation_rules_coverage`.
- **`source_id`**: `comune_bologna_opendata` non è ancora in source-observatory. Da aprire un intake issue / source-check per la tracciabilità (campo obbligatorio a standard).
- **`primary_key` clean**: `(data, id_spira, livello, fascia_oraria)` — unico verificato empiricamente sul parquet 2026 (6.310.560 righe → 6.310.560 chiavi distinte) e sul 2025.
- **Chiave spira `id_spira`**: `id_uni` quando presente, altrimenti `'chiave:<chiave>'`. Namespace obbligatorio: `chiave` e `id_uni` condividono 728 valori nel 2025, quindi un semplice `COALESCE` produrrebbe collisioni tra spire diverse. `id_uni` resta NULL per le 52 spire 2026 (nessun ID inventato). `livello` NULL → `-1` ("non registrato nella fonte") per tenere la PK non nulla.
- **`num_spire` nel mart**: conta `id_spira`, non `id_uni`, così le 52 spire 2026 entrano nel conteggio per via.
- **Benchmark nel mart**: `rank_passaggi_anno` in `mart_spire_sintesi` (PERCENT_RANK) segue il pattern comuni/sintesi/trend del candidate-standard.
- **POC**: 5 anni (2022-2026), non la serie completa — sufficiente per valutare il flusso toolkit.
