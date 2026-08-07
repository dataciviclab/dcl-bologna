# incarichi — incarichi di collaborazione e consulenza del Comune di Bologna

**Domanda civica**: a chi affida incarichi il Comune di Bologna, quanto spende e per quali attività? E gli stessi soggetti lavorano anche con altri enti (ANAC)?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Trasparenza
- **Dataset ODS**: `incarichi-di-collaborazione` — export parquet diretto, unico multi-anno, update weekly
- **Granularità**: atto (1 riga = 1 incarico)
- **Periodo**: 2012–2026 (750 righe)

## Struttura

```
datasets/incarichi/
├── dataset.yml
├── sql/
│   ├── clean.sql                     # anno derivato + typing
│   ├── mart_incarichi_anno.sql       # incarichi e importi per anno
│   ├── mart_incarichi_tipo.sql       # per classificazione (X1, X2, ...)
│   └── mart_incarichi_soggetti.sql   # per soggetto + partita_iva (cross ANAC)
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2026 --config datasets/incarichi/dataset.yml
```

## Output minimo atteso

- `mart_incarichi_anno`: trend incarichi e importi 2012→2026
- `mart_incarichi_tipo`: quota per tipologia di incarico
- `mart_incarichi_soggetti`: top soggetti con partita_iva — pronto per il cross ANAC (analisi 05)

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/tokkit-spire`.
