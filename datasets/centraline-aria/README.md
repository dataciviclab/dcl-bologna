# centraline-aria — qualità dell'aria, rilevazioni orarie da centraline fisse

**Domanda civica**: com'è l'aria a Bologna? Come varia per stazione, ora e inquinante? E c'è relazione tra traffico e inquinamento?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Ambiente
- **Dataset ODS** (due export uniti, schemi diversi):
  - `centraline-qualita-aria` — anno corrente, orario (2026 + coda di fine 2025)
  - `dati-centraline-bologna-storico` — serie storica 2017 → 2025-12-30, 696.683 righe
- **Formato raw**: parquet (~0,4 MB + ~3 MB)
- **Granularità**: oraria × stazione (3) × agente inquinante (8)
- **Periodo**: 2017–2026 (il clean contiene anche 17 righe del 30-31/12/2016, coda dell'export storico: restano, ma sono fuori dal periodo dichiarato)
- **Unità**: µg/m³ per tutti gli inquinanti **tranne CO, in mg/m³** (colonna `um`)

### Cosa copre davvero

Non è una griglia uniforme: gli inquinanti non hanno la stessa copertura né la stessa granularità.

| Inquinante | Stazioni | Granularità | Colonna da controllare |
|---|---|---|---|
| NO2 | 3 | oraria | `misura_affidabile` |
| PM10 | 3 | **giornaliera** (1 valore al giorno) | `misura_affidabile` |
| O3 | 2 | oraria | — |
| PM2.5 | 2 | **giornaliera** | — |
| CO, NO, NOX | 1 (Porta San Felice) | oraria | `misura_affidabile` |
| C6H6 | 1 (Porta San Felice) | oraria | — |

`misura_affidabile = FALSE` segnala le misure non comparabili con gli altri anni:
oggi solo il canale NOx di Porta San Felice nel 2024 (difetto strumentale, vedi `notes.md`).

## Struttura

```
datasets/centraline-aria/
├── dataset.yml
├── sql/
│   ├── clean.sql                  # unione due fonti + normalizzazione + dedup
│   ├── mart_aria_stazione.sql     # anno × stazione × inquinante (media, max, % sopra soglia)
│   ├── mart_aria_mese.sql         # serie mensile (la granularità per valutare una policy)
│   └── mart_aria_ora.sql          # profilo orario per anno × stazione × inquinante
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run --config datasets/centraline-aria/dataset.yml
```

## Output minimo atteso

- `mart_aria_stazione`: medie, massimi, giorni sopra soglia per anno, stazione e inquinante
- `mart_aria_mese`: serie mensile per stazione × inquinante — confronto prima/dopo Città 30 (gen 2024)
- `mart_aria_ora`: profilo orario per anno — il NO2 di punta si confronta col traffico (spire/varchi)

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/toolkit-spire`.
