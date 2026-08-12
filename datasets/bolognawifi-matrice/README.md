# bolognawifi-matrice — Matrice spostamenti WiFi (2021-2025)

**Domanda civica**: dove si muovono i pedoni a Bologna e a che ora? Quali rotte tra le zone sono le più battute?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — BolognaWiFi
- **Dataset ODS**: `bolognawifi-matrice-spostamenti-storico` — export parquet diretto, **unico multi-anno**
- **Formato raw**: parquet, 9 colonne, ~10 MB
- **Granularità**: zona WiFi origine × zona WiFi destinazione × ora
- **Periodo**: 2021-04 → 2025-12 (2021 parziale: parte ad aprile, 275 giorni)

## Perché vale la pena

- È la **matrice origine-destinazione della mobilità pedonale** in città — dato raro, pochi comuni italiani lo pubblicano
- 63 zone WiFi (piazze, musei, stazioni, portici): i flussi raccontano dove vanno le persone a piedi
- Completa la trilogia mobilità del repo: ZTL (auto dentro, analisi 07), spire (auto fuori, analisi 09), **WiFi (pedoni)**
- Serie 2021-2025: stagionalità, eventi, impatto turistico (incrociabile con eventi cultura, issue #5)

## Struttura

```
datasets/bolognawifi-matrice/
├── dataset.yml
├── sql/
│   ├── clean.sql                 # anno derivato + giorno split + typing
│   ├── mart_wifi_anno.sql        # flussi per anno + media/giorno
│   ├── mart_wifi_ora.sql         # profilo orario (forma della giornata)
│   └── mart_wifi_od.sql          # top 20 rotte origine→destinazione
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run raw   --config datasets/bolognawifi-matrice/dataset.yml
toolkit run clean --config datasets/bolognawifi-matrice/dataset.yml
toolkit run mart  --config datasets/bolognawifi-matrice/dataset.yml
```

## Output atteso

- `mart_wifi_anno`: 5 righe (2021-2025) — flussi totali e media/giorno per anno
- `mart_wifi_ora`: 24 righe — flussi medi per ora (picco pedonale ~11-17)
- `mart_wifi_od`: top 20 rotte per volume (es. Palazzo D'Accursio ↔ Piazza Maggiore ~6,6M flussi)

## Stato / prossimo passo

Issue [#34](https://github.com/dataciviclab/dcl-bologna/issues/34). Candidate verificato: readiness ready (8/8), quality 100/100, clean 1.469.826 righe.
