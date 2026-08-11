# notes.md — indici-fragilita

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`yyyy` è DATE nel parquet** (es. `2023-01-01`), non INTEGER — stesso quirk di popolazione-quartiere. Il clean deriva l'anno con `EXTRACT(YEAR FROM yyyy)` → INTEGER.
- **`perc_ab_no` è interamente NULL** (270/270) → escluso dal clean. Se in futuro la fonte lo valorizza, va riaggiunto.
- **`aree_escl=1`**: aree escluse dal calcolo degli indici dalla fonte (ospedali, parchi, zone industriali — residenti < ~150, es. "Fiera", "CNR", "Ospedale Sant'Orsola", "Giardini Margherita"). In queste aree `frag_*` e `rmpe_fam` sono NULL (nel 2023 compaiono come 0). Escluse nei mart con `aree_escl = 0`.
- **`cluster_an`**: cluster gerarchico (analisi nativa della fonte), 0=escluso. Valori 1-4/5 ma **senza etichette semantiche ufficiali** nel dataset → nel mart resta numerico, non inventiamo nomi.
- **`codareast`** = codice area statistica (stessa chiave di `area_statistica`), `zona_pross` = zona di prossimità (aggregazione intermedia area→quartiere).

## Rischi noti

- **⚠️ DRIFT DI SCALA nella fonte dal 2022** (bug Ufficio di Statistica, verificato su CSV ODS):
  - `rmpe_fam`: 2021 in **euro** (es. 22.148), 2022+ in **migliaia di euro** (es. 22,7). Ratio ~1000 costante su quasi tutte le aree. **Eccezione**: nel 2023 la fonte riattiva due aree escluse (Scalo Ravone, Lungo Savena) con `rmpe_fam` di nuovo in euro (25.605 e 13.362) → la normalizzazione `×1000` per anno>2021 è **sbagliata per quelle righe**.
  - `pop_res`: 2021 in **abitanti** (max 12.854), 2022+ con **bug non uniforme** — aree con pop 2021 > ~1.000 divise per 1000 (es. XXI Aprile 12.854→12), aree ≤ 1.005 lasciate in unità (es. Savena Abbandonato 1.005→999). Non esiste un fattore unico → `pop_res` **non affidabile cross-anno**.
  - **Conseguenza**: `pop_res` e `rmpe_fam` restano nel clean ma sono **esclusi dai mart** (non normalizzabili in modo affidabile senza mapping area-specifico fragile). Il mart usa solo gli indici sintetici `frag_*`, stabili tra anni, con **media semplice** (non ponderata per pop).
- **2023 parziale o diverso**: nel 2023 `frag_compl` minimo è 0 e il 2021/2022 hanno alcune righe senza `cluster_an` (12 e 9) — la fonte stessa cambia la copertura del cluster tra anni. Verificare a ogni refresh.
- **Serie corta**: 3 anni (2021-2023) — non è un blocco, la domanda regge, ma niente trend lunghi.
- **Fonte non ancora in source-observatory**: `source_id: comune_bologna_opendata` è un placeholder condiviso con gli altri dataset del repo (stessa nota di spire/colonnine).

## Decisioni metodologiche

- **`primary_key` clean**: `(anno, area_statistica)` — verificato empiricamente (270 righe = 270 chiavi).
- **`anno` derivato da `yyyy`** (INTEGER già nel raw) — a differenza di popolazione-quartiere qui l'anno non è DATE.
- **Mart area**: rank per indice (`PERCENT_RANK`) come benchmark nel comune; aree escluse fuori.
- **Mart quartiere**: media **semplice** degli indici (NON ponderata per `pop_res`) per il drift di scala della fonte. Documentato in issue #31 / questo notes.
- **`rmpe_fam_media_eur`**: rimosso dal mart — non normalizzabile in modo affidabile (eccezione 2023). Documentato in issue #31 / questo notes.
- **`quota_pct_aree_cluster_alto`**: quota di *aree* nell'anno col `cluster_an` più alto presente quell'anno — confrontabile tra anni solo con cautela (il cluster max varia).
