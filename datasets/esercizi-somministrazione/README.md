# esercizi-somministrazione — Esercizi di somministrazione (bar/ristoranti)

**Domanda civica**: dov'è il tessuto commerciale di Bologna e come è cambiato? Dove si svuota?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — SUAP / Commercio
- **Dataset ODS**: `elenco-esercizi-somministrazioni` — export parquet diretto
- **Formato raw**: parquet, 21 colonne, ~515 KB
- **Granularità**: esercizio (via + civico + tipologia)
- **Periodo**: apertura dal 1976, cessazione fino al 2026

## Perché vale la pena

- È lo **storico completo del tessuto di bar/ristoranti**: 17.981 record, 3.016 attivi oggi
- `data_inizio`/`data_cessazione` → analisi di **desertificazione commerciale** (sopravvivenza per decade, cessazioni per anno)
- Geolocalizzato + `area_statistica` → incrocio con reddito (issue #32), fragilità (issue #31) e mobilità
- `bottega_storica` (11 attività) e `centro_storico` → letture su patrimonio commerciale

## Struttura

```
datasets/esercizi-somministrazione/
├── dataset.yml
├── sql/
│   ├── clean.sql                        # typing + normalize + dedup
│   ├── mart_esercizi_quartiere.sql      # esercizi per quartiere × stato
│   └── mart_esercizi_stato.sql          # esercizi per stato
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run raw   --config datasets/esercizi-somministrazione/dataset.yml
toolkit run clean --config datasets/esercizi-somministrazione/dataset.yml
toolkit run mart  --config datasets/esercizi-somministrazione/dataset.yml
```

## Output atteso

- `mart_esercizi_quartiere`: 27 righe (quartiere × stato) — attivi/cessati per quartiere
- `mart_esercizi_stato`: 4 righe (Attivo/Cessato/Sospeso/Diniegato)

## Stato / prossimo passo

Issue [#33](https://github.com/dataciviclab/dcl-bologna/issues/33). Candidate verificato: readiness ready (8/8), quality 100/100, clean 17.981 righe.
