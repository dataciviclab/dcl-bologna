# reddito-mediano — Reddito mediano per area statistica (2016-2024)

**Domanda civica**: dove si concentra il reddito a Bologna? Quali aree crescono e quali si impoveriscono?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio di Statistica
- **Dataset ODS**: `reddito-mediano-per-area-statistica` — export parquet diretto, unico multi-anno
- **Formato raw**: parquet, 4 colonne, ~7 KB
- **Granularità**: area statistica × anno
- **Periodo**: 2016-2024 (9 anni)

## Perché vale la pena

- È la **base del blocco economia per area**: reddito imponibile mediano dei contribuenti residenti per ciascuna delle ~91 aree
- Chiave `area_statistica` **condivisa** con `indici-fragilita` e `elenco-esercizi-somministrazioni` → join 1:1 per incrociare reddito × fragilità × commercio
- Serie 9 anni: crescita/declino per area, effetto del ricambio demografico (reddito vs numero contribuenti)
- Validazione incrociata possibile con `irpef_comunale` (cross-lab, livello comunale)

## Struttura

```
datasets/reddito-mediano/
├── dataset.yml
├── sql/
│   ├── clean.sql                 # anno derivato + alias colonne + typing
│   └── mart_reddito_area.sql     # reddito per area × anno + rank nel comune
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run raw   --config datasets/reddito-mediano/dataset.yml
toolkit run clean --config datasets/reddito-mediano/dataset.yml
toolkit run mart  --config datasets/reddito-mediano/dataset.yml
```

## Output atteso

- `mart_reddito_area`: 817 righe (91 aree × 9 anni) — reddito mediano, contribuenti, rank nel comune

## Stato / prossimo passo

Issue [#32](https://github.com/dataciviclab/dcl-bologna/issues/32). Candidate verificato: readiness ready (8/8), quality 100/100, clean 817 righe.
