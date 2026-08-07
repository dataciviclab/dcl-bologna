# convivenze — popolazione residente in istituti di convivenza

**Domanda civica**: quante persone vivono in istituti di convivenza a Bologna (strutture, pensionati, comunità)? Come cambia nel tempo?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio di Statistica
- **Dataset ODS**: `popolazione-residente-in-istituti-di-convivenza-per-cittadinanza-eta-dimensione-...`
- **Granularità**: anno × quartiere × zona × cittadinanza × dimensione × età × sesso
- **Periodo**: 1986–2024 (92.633 righe)

## Struttura

```
datasets/convivenze/
├── dataset.yml
├── sql/
│   ├── clean.sql                     # anno derivato + typing
│   └── mart_convivenze_tipo.sql      # residenti per dimensione struttura × anno
├── README.md
└── notes.md
```

## Run

```bash
toolkit run --years 2024 --config datasets/convivenze/dataset.yml
```

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/toolkit-spire`.
