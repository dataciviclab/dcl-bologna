# popolazione-quartiere — popolazione residente per età, sesso, cittadinanza, quartiere, zona

**Domanda civica**: come è cambiata la popolazione dei quartieri di Bologna dal 1986? Chi invecchia più in fretta, quali zone crescono o si svuotano?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio Comunale di Statistica
- **Dataset ODS**: `annuale_popolazione_residente_eta_quart_zonadal1986` — export parquet diretto, **unico multi-anno**
- **Formato raw**: parquet (~0,9 MB), 10 colonne
- **Granularità**: quartiere × zona × età (singolo anno) × sesso × cittadinanza
- **Periodo**: 1986–2024

## Perché vale la pena

- È il dataset demografico di riferimento di Bologna: serie storica completa dal 1986
- Incroci: popolazione vs mobilità (spire, varchi, bici), vs aria
- Qui si chiude la **issue #14**: lo yml legacy dichiarava `anno: int` ma il parquet è DATE → nel toolkit il clean deriva l'anno correttamente e `required_columns`/`not_null` prevengono il mismatch

## Struttura

```
datasets/popolazione-quartiere/
├── dataset.yml
├── sql/
│   ├── clean.sql                    # anno derivato + typing
│   ├── mart_pop_quartiere.sql       # per quartiere × anno + benchmark (indice vecchiaia)
│   └── mart_pop_trend.sql           # trend 1986→2024 per quartiere (CAGR)
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run --years 2024 --config datasets/popolazione-quartiere/dataset.yml
toolkit inspect config --config datasets/popolazione-quartiere/dataset.yml
```

## Output minimo atteso

- `mart_pop_quartiere`: residenti, quota, indice di vecchiaia per quartiere e anno
- `mart_pop_trend`: variazione 1986→2024 e CAGR per quartiere

## Stato / prossimo passo

Fase 2 del piano di migrazione dcl-bologna → toolkit. Branch `poc/tokkit-spire`.
