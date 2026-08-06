# colonnine-bici — passaggi orari dalle colonnine conta-bici

**Domanda civica**: dove e quando si muove Bologna in bici? Quali quartieri sono più serviti e più usati? E come si confrontano i flussi bici con quelli auto (spire, varchi ZTL)?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Trasporti
- **Dataset ODS**: `colonnine-conta-bici` — export parquet diretto, **unico multi-anno**
- **Formato raw**: parquet (~3 MB), 24 colonnine
- **Granularità**: colonnina × data (oraria) × direzione (centro/periferia)
- **Periodo**: 2018–2026
- **Arricchimento**: join con `mapping/colonnine-quartieri.csv` (24 colonnine → quartiere/zona/via)

## Perché vale la pena

- È il complemento ciclabile di spire-traffico (auto): stesso tema, stessa geometria
- Il mapping quartieri (già presente in dcl-bologna) diventa un join in clean.sql, non più un file a parte da ricordare
- Mart per quartiere e per fascia oraria: risponde a "quali quartieri si muovono in bici, quando"

## Struttura

```
datasets/colonnine-bici/
├── dataset.yml
├── sql/
│   ├── clean.sql                  # dedup + anno derivato + join mapping
│   ├── mart_colonnine_anno.sql    # per colonnina × anno + benchmark
│   ├── mart_colonnine_quartiere.sql  # per quartiere × anno
│   └── mart_colonnine_ora.sql     # profilo orario per quartiere
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run all --config datasets/colonnine-bici/dataset.yml
toolkit inspect config --config datasets/colonnine-bici/dataset.yml
```

## Output minimo atteso

- `mart_colonnine_anno`: quali colonnine hanno più passaggi, come rankano per anno
- `mart_colonnine_quartiere`: traffico bici per quartiere, quota e rank
- `mart_colonnine_ora`: picchi orari per quartiere

## Stato / prossimo passo

Dataset semplice migrato al toolkit (POC dcl-bologna). Branch `poc/toolkit-spire`.
