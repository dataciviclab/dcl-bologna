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
- **Coda 2016**: 17 righe del 2016-12-30/31 (le prime ore della serie). Restano nel clean, ma
  `time_coverage.start_year` è 2017: per i confronti annuali il 2016 non è utilizzabile.
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

- **Copertura non uniforme**: solo NO2 e PM10 hanno 3 stazioni; CO, NO, NOX e C6H6 esistono
  soltanto a Porta San Felice. Qualunque conclusione "di città" su quegli inquinanti è impropria.
- **PM10 e PM2.5 non sono orari**: la fonte li pubblica come valore giornaliero (stampato alle
  23:00, con qualche ora sporadica in più). `mart_aria_ora` li esclude per questo.
- **NO/NOX si fermano il 2026-09-16**: il 2026 non è comparabile su quegli agenti.
- **Il 2026 è parziale** (fermo a novembre, e NO/NOX a settembre): il confronto va fatto su
  finestre comparabili (o su `mart_aria_mese`), non sui totali annui.
- **Soglie**: `pct_sopra_soglia` (PM10>50, NO2>40, O3>120) sono riferimenti indicativi, non
  normativi. La quota è su ore per NO2/O3 e su giorni per PM10/PM2.5.
- **2023 è l'anno più pulito della serie PM10** (3 giorni sopra 50 contro 11-28 degli altri anni):
  usarlo come baseline pre-Città 30 gonfia qualunque effetto. Meglio media 2021-2023.
- **`source_id`**: `comune_bologna_opendata` placeholder condiviso con gli altri dataset del repo.

## Difetto strumentale a Porta San Felice (2024)

Il calo di NO2 del 2024 sembrava un effetto Città 30 (−32% a Porta San Felice, −20% sulla media
città). Non lo è: la serie della stazione di traffico non è comparabile in quell'anno.

| Evidenza | Dato |
|---|---|
| Non è uno scalino a gennaio | calo progressivo da maggio, minimo a settembre-ottobre 2024 |
| Profilo orario | a set-ott 2024 la curva ha la stessa forma del 2023, scalata a ~⅓ |
| NO vs NO2 | NO **+51%** mentre NO2 **−63%** nella stessa finestra |
| Rapporto NO2/NOX | 0,27-0,42 a set-dic 2024 contro 0,66-0,79 negli stessi mesi 2023/2025 |
| Rientro | ottobre 2025: rapporto 0,67, NO2 di nuovo 42,9 µg/m³ |
| Altre stazioni | Giardini −3,2%, Chiarini +0,2% (piatte) |

Se fosse traffico, NO e NO2 scenderebbero insieme e il rapporto NO2/NOX resterebbe stabile.
La firma è quella del canale NOx (convertitore/calibrazione). CO (+18%), C6H6 (+8%) e PM10 (−5%)
della stessa stazione non mostrano lo stesso salto: il difetto è del canale NOx, non della stazione.

Il flag `misura_affidabile` è quindi FALSE per `(PORTA SAN FELICE, 2024, NO/NO2/NOX)`.
Va riesaminato se il Comune pubblica una revisione dei dati 2024.

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
- **`misura_affidabile` nel clean, non nel mart**: è un attributo dell'osservazione, non
  dell'aggregato. I mart lo propagano con `MIN(...)`, così un consumatore che filtra
  `misura_affidabile` non mescola anni comparabili e non comparabili.
- **`mart_aria_ora` solo inquinanti orari**: PM10/PM2.5 sono giornalieri e in un profilo orario
  produrrebbero una barra isolata alle 23:00.
- **`giorni_rilevati` = giorni distinti, non righe**: con agenti orari la vecchia definizione
  (COUNT(*)) restituiva le ore, non i giorni.
