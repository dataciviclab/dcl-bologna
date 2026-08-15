# notes.md — esercizi-somministrazione

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`stato`** è la dimensione chiave: `Attivo` (3.016), `Cessato` (14.936), `Sospeso` (27), `Diniegato` (2). Non coincide con `data_cessazione IS NULL`: 3.021 attivi con `data_cessazione` NULL vs 3.016 con stato Attivo — piccole discrepanze (5 record), usare `stato` come fonte di verità.
- **Quartieri "storici"**: 171 record (0,95%) hanno quartiere pre-2016 (Borgo Panigale, Porto, Reno, San Donato, San Vitale) — probabile residuo di codifica della fonte. Da normalizzare o escludere nelle aggregazioni per quartiere.
- **`bottega_storica`**: 11 record valorizzati (1) — nessuna lista ufficiale delle botteghe storiche nel dataset, il campo è una flag parziale.
- **`centro_storico`**: valorizzato come "(centro storico)" per le aree dentro la cerchia; NULL fuori. Non confondere con l'omonimo campo di popolazione-quartiere.

## Rischi noti

- **Lo storico non è un censimento attivo per anno**: le date di inizio/cessazione permettono di ricostruire il flusso, ma il dataset è uno snapshot con lo stato attuale — non è una serie temporale completa (le attività cessate hanno la data, ma non sappiamo se mancano attività mai registrate).
- **Duplicati**: ~726 righe duplicate per chiave (via, civico, tipologia, inizio, stato) — dedup nel clean con GROUP BY (3,9%). Possono rappresentare sub-unità (interni, locali) dello stesso esercizio.
- **3 record completamente vuoti** nella fonte (stato 'non definita', nessuna via/geo) — esclusi nel clean.
- **Sopravvivenza per decade da leggere con cautela**: gli esercizi aperti nel 2020+ hanno avuto meno anni per cessare (effetto finestra temporale). Il confronto decade-decade è indicativo, non un tasso di mortalità rigoroso.
- **Fonte non ancora in source-observatory**: `source_id: comune_bologna_opendata` placeholder condiviso con gli altri dataset del repo.

## Decisioni metodologiche

- **`primary_key` clean**: `(esercizio_via, civico, tipologia_esercizio, data_inizio_attivita, stato)` — verificata empiricamente dopo dedup (17.984 = 17.984, poi -3 vuoti = 17.981).
- **`stato` come verità** per attivo/cessato (non `data_cessazione`).
- **Dedup con GROUP BY** (non ROW_NUMBER) — lezione varchi-ztl, riproducibile.
- **Niente geopoint BLOB** nel clean: lat/lon già presenti (ridondante).
- **Colonne droppate con giustificazione empirica** (fix review): `area` = 1 valore costante su 18.710 righe (zero informazione); `attivita_prevalente_esercizio` = 0 valori non-null (colonna morta). `sottoarea` (natura giuridica: al pubblico/deroga/riservata) e `attivita_secondaria` (offerta accessoria: radio, videogiochi, mense — 428 valori) sono **informazione preservata nel clean** — prima erano state escluse per errore, ripristinate.
- **Chiave con `area_statistica`** condivisa con reddito-mediano e indici-fragilita → join 1:1 per il blocco economia.
- **Flag `quartiere_attuale` nel mart** (review PR #45): separa i 6 quartieri correnti dai valori soppressi nel 2016 (Borgo Panigale, Porto, Reno, San Donato, San Vitale, Saragozza). Chi consuma il mart filtra `quartiere_attuale = TRUE` — l'analisi 12 usa il flag, non un NOT IN hardcoded.
- **`area_statistica` in MAIUSCOLO nella fonte** (verificato: 17.659/17.659 righe UPPER): reddito-mediano e indici-fragilita usano case normale (es. `Marconi-2` vs `MARCONI-2`). Il join cross del blocco economia richiede **`UPPER(area_statistica)`** su entrambi i lati — documentato per l'analisi cross (13). Match verificato: 88 aree su tutti e 3 i dataset con UPPER.
- **Due definizioni di "centro storico"** (review PR #45): (a) campo `centro_storico` della fonte → 35,9% degli attivi; (b) quartieri Santo Stefano + Porto-Saragozza → 51,9%. La discussion #44 usa la (b); l'analisi Q1 usa la (a). Da definire quale è canonica nel Lab.
