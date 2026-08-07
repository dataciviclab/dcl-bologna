# emigrati-destinazione — emigrati per destinazione, sesso, quartiere, zona

**Domanda civica**: chi lascia Bologna e dove va? Quali quartieri perdono più residenti?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio di Statistica
- **Dataset ODS**: `emigrati-secondo-la-destinazione-per-sesso-quartiere-e-zona-di-provenienza-serie`
- **Granularità**: anno × destinazione × quartiere × zona × sesso
- **Periodo**: 1986–2024 (81.806 righe)

## Struttura

```
datasets/emigrati-destinazione/
├── dataset.yml
├── sql/
│   ├── clean.sql                     # anno derivato + typing
│   └── mart_emigrati_quartiere.sql   # emigrati per quartiere × anno + quota
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2024 --config datasets/emigrati-destinazione/dataset.yml
```

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/toolkit-spire`.
