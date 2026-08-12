# notes.md — bolognawifi-matrice

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`data` è DATE** nel parquet (es. `2025-12-31`), non stringa — il clean deriva l'anno con `EXTRACT(YEAR FROM data)`.
- **`giorno` è "1-Lunedì"** (numero-label attaccati da `-`) → il clean splitta in `giorno_num` (INTEGER, 1=Lunedì..7=Domenica) e `giorno_label` (VARCHAR). Verificato: 7 valori, nessun altro.
- **2021 parziale**: la serie parte da **2021-04-01** (275 giorni, non 365). I confronti anno-anno vanno fatti su **media/giorno** (`flussi_giorno` nel mart), mai sui totali annuali.
- **2025 parziale**: 353 giorni (fino al 2025-12-31 — verificare a ogni refresh; al run attuale 353 giorni, coerente con la fine anno).
- Il dataset è lo **storico**: esiste un fratello "aggiornato" (`bolognawifi-matrice-spostamenti`) con feed più recente. Se serve il dato corrente, va valutata la migrazione al feed live.

## Rischi noti

- **Copertura zone variabile nel tempo**: il numero di zone WiFi attive può cambiare tra anni (63 zone distinte nel totale). I mart OD aggregati sulla serie completa mescolano periodi con zone diverse → le rotte top vanno lette come "dove si è camminato di più nell'intero periodo", non come dato anno-specifico.
- **`percentile_50`**: incluso nel clean (raw-faithful) ma non usato nei mart — significato non documentato nella fonte. Verificare prima di usarlo in analisi.
- **Semantica "flusso"**: `totale` è il numero di dispositivi connessi spostatisi tra zone (approssimazione pedoni reali, non conteggio persone). Da dichiarare in ogni analisi: è un **proxy di mobilità pedonale**, non un censimento.
- **Fonte non ancora in source-observatory**: `source_id: comune_bologna_opendata` è un placeholder condiviso con gli altri dataset del repo.

## Decisioni metodologiche

- **`primary_key` clean**: `(data, ora, id_origine, id_destinazione)` — verificata empiricamente (1.469.826 righe = 1.469.826 chiavi).
- **`anno` derivato da `data`** (multi-anno, `{year}` è solo il run year).
- **Id vs label**: il clean mantiene sia `id_*` (chiave stabile) sia `label_*` (leggibile). I mart usano le label per leggibilità, l'analisi può agganciarsi agli id.
- **Mart separati per query** (lezione: un file mart = UNA query; la seconda query in un file viene ignorata dal runner).
- **`flussi_giorno`** nel mart_wifi_anno normalizza su giorni coperti — mai confrontare i totali 2021 (275g) con 2024 (366g).
