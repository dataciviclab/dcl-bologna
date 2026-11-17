# notes.md — centraline-aria

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **Due export, due schemi**: `centraline-qualita-aria` (orario, anno corrente) espone
  `reftime/stazione/value/agente_atm`; `dati-centraline-bologna-storico` (2017 → 2025-12-30)
  espone `cod_staz/agente/data_inizio/valore/um`. Nessun ID comune tra i due.
- **Stazione**: nel dataset corrente il nome porta l'indirizzo (`"GIARDINI MARGHERITA, BOLOGNA VIALE
  BOTTONELLI"`), nello storico è il solo nome (`"GIARDINI MARGHERITA"`). Il clean tiene il nome
  corto (no-op per lo storico) — le 3 stazioni coincidono.
- **Agenti**: due vocabolari. Storico `C6H6 (BENZENE)`, `NOX (OSSIDI DI AZOTO)`, `NO (MONOSSIDO DI
  AZOTO)`…; corrente `Benzene`, `NOX (Ossidi di azoto)`, `NO`, `NO2`, `O3`, `PM10`, `PM2.5`.
  Il clean normalizza su 8 codici corti con un CASE esplicito.
- **Unità**: lo storico porta `um` per riga; il dataset corrente non la espone. **CO è in mg/m³**,
  tutti gli altri in µg/m³. Il clean espone la colonna `um` perché aggregare sostanze diverse senza
  leggerla mescola unità di misura.
- **Etichetta `um` sbagliata sulla fonte (CO, 2025)**: 7.583 righe CO (7.582 del 2025 + 1 del 2024)
  dichiarano `um = 'ug/m3'`, ma i valori stanno sulla scala mg/m³ (0,0–2,0, identica alle altre righe
  CO). Il clean forza CO su `mg/m3`: lasciare l'etichetta errata renderebbe `um` inaffidabile.
- **Coda 2016**: 17 righe del 2016-12-31 (le prime ore della serie). Restano, ma `time_coverage`
  parte dal 2016 per non dichiarare il falso; per i confronti annuali il 2016 non è utilizzabile.
- **Intervallo orario nello storico**: `data_inizio` è `HH:01`, `data_fine` `HH+1:00`. L'ora di
  riferimento è `date_trunc('hour', data_inizio)`, identica a `reftime` del dataset corrente.
- **Cambio ora legale**: 287 righe duplicate su `(ora, stazione, agente)` nello storico (stessa
  collisione delle 9 coppie 2026). Dedup: preferisco la fonte corrente, poi il valore maggiore.
- **12 righe senza misura**: PM2.5 a Giardini Margherita, febbraio-aprile 2023, `valore` NULL
  (buco del sensore). Scartate nel clean.
- **Valori negativi**: lo storico contiene NO2 negativi (min −2,0) — rumore strumentale, non
  corretto: resta visibile. Chi aggrega deve saperlo.
- **Buco al confine tra le fonti**: lo storico si ferma all'ora 2025-12-29 23:00; il dataset
  corrente riparte con 14 sole letture il 2025-12-31. Manca il **2025-12-30** (giorno intero) e quasi
  tutto il 31/12: **nella fonte**, non nel clean.
- **`id` non è unico** nel dataset corrente (46.319 id distinti su 46.397 righe) — non usato come chiave.

## Rischi noti

- **Confini 2016 e 2026 sono parziali**: 17 righe nel 2016 e la serie 2026 ferma a ottobre; il
  confronto va fatto su finestre comparabili (o su `mart_aria_mese`), non sui totali annui.
- **Soglie**: `pct_ore_sopra_soglia` (PM10>50, NO2>40, O3>120) e la quota in
  `mart_aria_stazione` sono riferimenti indicativi, non normativi.
- **Tre stazioni non coprono la città**: Giardini Margherita (parco), Porta San Felice e Via
  Chiarini (traffico). Le medie comunali non sono rappresentative di tutti i quartieri.
- **`source_id`**: `comune_bologna_opendata` placeholder condiviso con gli altri dataset del repo.

## Decisioni metodologiche

- **Un solo dataset, due source**: le due fonti sono la stessa serie spezzata, non due fenomeni.
  `clean.read.mode: "all"` unisce i due parquet; `fonte` (`ods_2026` / `storico`) è derivata in SQL
  dalla colonna presente (`reftime` vs `data_inizio`).
  **Perché non `inject_column`**: con schemi diversi il toolkit costruisce un `UNION ALL` posizionale
  di `SELECT *` per file, che fallisce ("Set operations can only apply to expressions with the same
  number of result columns").
- **`primary_key` clean**: `(reftime, stazione, agente_atm)` — unica dopo dedup.
- **`anno` obbligatorio nei mart**: `mart_aria_ora` senza `anno` mescolerebbe otto anni in un unico
  profilo orario. Aggiunto in questa estensione.
- **`mart_aria_mese`**: aggiunto per la valutazione di policy (Città 30 da gennaio 2024). La
  granularità annuale nasconde il punto di rottura.
- **CO escluso dalle soglie**: è in mg/m³, quindi non ha una soglia confrontabile con le altre.
