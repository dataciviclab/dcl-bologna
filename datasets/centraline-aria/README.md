# centraline-aria — qualità dell'aria, rilevazioni orarie da centraline fisse

**Domanda civica**: com'è l'aria a Bologna? Come varia per stazione, ora e inquinante? E c'è relazione tra traffico e inquinamento?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Ambiente
- **Dataset ODS**: `centraline-qualita-aria` — export parquet diretto, unico (2026)
- **Formato raw**: parquet (~0,4 MB)
- **Granularità**: oraria × stazione (3) × agente inquinante (8)
- **Periodo**: 2025–2026 (storico in `dati-centraline-bologna-storico`)

## Struttura

```
datasets/centraline-aria/
├── dataset.yml
├── sql/
│   ├── clean.sql                  # anno derivato + dedup cambio ora legale
│   ├── mart_aria_stazione.sql     # per stazione × inquinante (media, max, % sopra soglia)
│   └── mart_aria_ora.sql          # profilo orario per stazione × inquinante
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run --years 2026 --config datasets/centraline-aria/dataset.yml
```

## Output minimo atteso

- `mart_aria_stazione`: medie, massimi, giorni sopra soglia per stazione e inquinante
- `mart_aria_ora`: profilo orario — il NO2 di punta si confronta col traffico (spire/varchi)

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/tokkit-spire`.
