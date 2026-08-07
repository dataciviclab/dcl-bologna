# spire-traffico — flusso veicoli tramite spire

**Domanda civica**: come cambia il traffico sulle strade fuori dal centro di Bologna? I varchi ZTL coprono il centro, le spire coprono il resto della città — insieme danno il quadro completo della mobilità.

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Trasporti
- **Dataset ODS**: `rilevazione-flusso-veicoli-tramite-spire-anno-{year}` (2022–2025 in questo candidate)
- **Formato raw**: export parquet diretto (single file per anno, ~17 MB/anno)
- **Granularità**: spira × data × fascia oraria (24 fasce) — ~304k righe/anno wide, ~7,3M righe/anno long
- **Periodo**: 2022–2025 (POC: anni campione della famiglia "flusso"; la famiglia completa ha anche `rilevazione-autoveicoli-*` 2019-2021 e `accuratezza-*`)

## Perché vale la pena

- Complementare ai varchi ZTL (issue #9 di dcl-bologna): le spire coprono le strade fuori ZTL
- Incroci possibili: bici (conta-bici) vs auto, traffico vs inquinamento (centraline aria)
- Il raw è **wide** (24 colonne orarie): è il primo dataset Bologna che richiede un vero `clean.sql` (UNPIVOT) — il toolkit dimostra qui il suo valore rispetto al fetch parquet "as-is"

## Struttura

```
datasets/spire-traffico/
├── dataset.yml              # config standard toolkit (modello eurostat)
├── sql/
│   ├── clean.sql            # UNPIVOT wide→long + typing + fascia label
│   ├── mart_spire_sintesi.sql  # passaggi per via × anno + benchmark rank
│   ├── mart_spire_ora.sql      # profilo orario per via × anno
│   └── mart_spire_trend.sql    # CAGR multi-anno per via
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run all --config datasets/spire-traffico/dataset.yml
toolkit status --config datasets/spire-traffico/dataset.yml
```

## Output minimo atteso

- `mart_spire_sintesi`: quali vie hanno più traffico, come rankano per anno
- `mart_spire_ora`: profilo orario — picchi di traffico per via
- `mart_spire_trend`: CAGR 2022→2025 per via — quali strade aumentano/diminuiscono

## Criterio di promozione

- Se il flusso toolkit regge (raw http_file parquet → clean UNPIVOT → mart) senza codice custom, il candidate è un test valido per valutare la migrazione di dcl-bologna al toolkit
- Estendere poi agli anni 2019-2021 (famiglia autoveicoli) e alle accuratezze

## Stato / prossimo passo

POC per valutare toolkit + dataset-standard in dcl-bologna. Branch `poc/toolkit-spire`.
