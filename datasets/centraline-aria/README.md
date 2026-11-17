# centraline-aria — qualità dell'aria, rilevazioni orarie da centraline fisse

**Domanda civica**: com'è l'aria a Bologna? Come varia per stazione, ora e inquinante? E c'è relazione tra traffico e inquinamento?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Ambiente
- **Dataset ODS** (due export uniti, schemi diversi):
  - `centraline-qualita-aria` — anno corrente, orario (2026 + coda di fine 2025)
  - `dati-centraline-bologna-storico` — serie storica 2017 → 2025-12-30, 696.683 righe
- **Formato raw**: parquet (~0,4 MB + ~3 MB)
- **Granularità**: oraria × stazione (3) × agente inquinante (8)
- **Periodo**: 2017–2026
- **Unità**: µg/m³ per tutti gli inquinanti **tranne CO, in mg/m³** (colonna `um`)

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
