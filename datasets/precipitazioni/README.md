# precipitazioni — precipitazioni giornaliere a Bologna (2001–2026)

**Domanda civica**: quanta pioggia cade a Bologna? Anni più secchi o più piovosi?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Ambiente
- **Dataset ODS**: `precipitazioni_bologna` — export parquet diretto, unico multi-anno
- **Granularità**: giornaliera — `date`, pioggia (mm), `stagione`
- **Periodo**: 2001–2026 (9.346 righe)

## Struttura

```
datasets/precipitazioni/
├── dataset.yml
├── sql/
│   ├── clean.sql                  # rinomina "184_avg_d" → pioggia_mm
│   └── mart_precipitazioni_anno.sql  # totale, giorni pioggia, max per anno
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2026 --config datasets/precipitazioni/dataset.yml
```

## Output atteso

- `mart_precipitazioni_anno`: pioggia totale, giorni di pioggia, massimo giornaliero per anno

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/tokkit-spire`.
