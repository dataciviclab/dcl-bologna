# indici-fragilita — indici di fragilità demografica, sociale ed economica per area statistica

**Domanda civica**: dove e quanto sono fragili i quartieri di Bologna? Quali zone invecchiano più in fretta, hanno famiglie più vulnerabili o redditi più bassi?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — Ufficio Comunale di Statistica
- **Dataset ODS**: `indici-di-fragilita-dal-2021` — export parquet diretto, **unico multi-anno**
- **Formato raw**: parquet, 30 colonne (29 dopo clean)
- **Granularità**: area statistica (90 aree) × anno
- **Periodo**: 2021–2023

## Perché vale la pena

- È la **sintesi ufficiale della fragilità** della città: 4 indici sintetici (`frag_demo`, `frag_soc`, `frag_econ`, `frag_compl`) + 26 indicatori analitici per area
- Chiave `area_statistica` **condivisa** con `reddito-mediano-per-area-statistica` e `elenco-esercizi-somministrazioni` → base del blocco "socio-economia" della scheda Bologna (issue #31)
- Incroci: fragilità vs demografia (`popolazione-quartiere`), vs mobilità/aria per zona

## Struttura

```
datasets/indici-fragilita/
├── dataset.yml
├── sql/
│   ├── clean.sql                        # anno derivato + typing esplicito
│   ├── mart_fragilita_area.sql          # per area × anno + rank
│   └── mart_fragilita_quartiere.sql     # sintesi per quartiere (media ponderata pop)
├── README.md
└── notes.md
```

Output toolkit in `out/` (root: `../../out`), gitignorato.

## Run

```bash
toolkit run --years 2023 --config datasets/indici-fragilita/dataset.yml
toolkit inspect config --config datasets/indici-fragilita/dataset.yml
```

## Output minimo atteso

- `mart_fragilita_area`: i 4 indici + cluster + reddito per area e anno, con rank nel comune
- `mart_fragilita_quartiere`: media ponderata degli indici per quartiere, reddito medio, quota nel cluster alto

## Stato / prossimo passo

Issue [#31](https://github.com/dataciviclab/dcl-bologna/issues/31) — candidate da verificare con `toolkit inspect`.
