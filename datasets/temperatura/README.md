# temperatura — temperature giornaliere a Bologna (2001–2026)

**Domanda civica**: come sta cambiando il clima a Bologna? Quanti giorni di caldo estremo per anno?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Ambiente
- **Dataset ODS**: `temperature_bologna` — export parquet diretto, unico multi-anno
- **Granularità**: giornaliera — `date`, `avg`, `max`, `min`, `stagione`
- **Periodo**: 2001–2026 (9.346 righe)

## Struttura

```
datasets/temperatura/
├── dataset.yml
├── sql/
│   ├── clean.sql                # typing
│   └── mart_temperatura_anno.sql  # medie, estremi, giorni >35° e gelo per anno
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2026 --config datasets/temperatura/dataset.yml
```

## Output atteso

- `mart_temperatura_anno`: media/estremi + giorni oltre 35° e sotto zero per anno

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/toolkit-spire`.
