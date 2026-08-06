# famiglie-tipologia — famiglie per età, tipologia e cittadinanza del capofamiglia

**Domanda civica**: com'è cambiata la struttura delle famiglie a Bologna dal 1986? Più persone sole, più monogenitori?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio di Statistica
- **Dataset ODS**: `famiglie-residenti-per-eta-tipologia-e-cittadinanza-del-capofamiglia-per-quartie...`
- **Granularità**: anno × quartiere × zona × età × tipo capofamiglia × sesso × cittadinanza
- **Periodo**: 1986–2024 (78.270 righe)

## Struttura

```
datasets/famiglie-tipologia/
├── dataset.yml
├── sql/
│   ├── clean.sql                      # anno derivato + typing
│   ├── mart_famiglie_tipo.sql         # per tipologia capofamiglia × anno
│   └── mart_famiglie_quartiere.sql    # per quartiere × anno
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2024 --config datasets/famiglie-tipologia/dataset.yml
```

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/tokkit-spire`.
