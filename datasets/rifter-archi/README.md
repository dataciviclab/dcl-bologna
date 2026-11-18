# rifter-archi — rete stradale e toponomastica (RIFTER)

**Domanda civica**: come si collega un punto (una colonnina, una spira, un varco) al quartiere e alla zona a cui appartiene, senza rifare una mappa a mano per ogni dataset?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Regioni e città
- **Dataset ODS**: `rifter_arcstra_li` — export parquet
- **Granularità**: arco stradale (8.048 archi, 1.972 vie), con coordinate lat/lon
- **Periodo**: snapshot della rete (data di istituzione degli archi 1990–2026)
- **Chiavi**: `codarco` (unico), `codvia` (codice ISTAT della via)

## Perché vale la pena

È l'anello che mancava per collegare i dati puntuali al territorio **senza mapping manuali**.
Nel repo c'erano tre CSV costruiti per distanza minima (`mapping/varchi-quartieri.csv`,
`colonnine-quartieri.csv`, `stazioni-aria.csv`): andavano rifatti per ogni nuovo dataset.

Verificato: le spire espongono `codice_via` e **320 vie su 320** trovano il quartiere
in questo dataset. Stessa cosa per la zona, con il join `codvia` → `quartiere`.

## Output

| Mart | Contenuto |
|---|---|
| `mart_via_quartiere` | crosswalk `codvia` → quartiere: 1.972 vie, di cui 120 su più quartieri (via di confine) — la chiave è `(codvia, quartiere)` |
| `mart_quartiere_archi` | rete per quartiere: archi, vie, lunghezza km — denominatore alternativo agli abitanti |

## Limiti

- **Niente `spatial`**: la sorgente è il **CSV**, dove `geo_point_2d` è testo; lat/lon sono
  esposte come DOUBLE e si può calcolare una distanza (haversine) senza estensione. Il parquet
  avrebbe richiesto `spatial` per `ST_X`/`ST_Y`. `geo_shape` (GeoJSON) resta fuori.
- **I varchi**: non hanno `codvia`, quindi non entrano nel crosswalk per codice. Con lat/lon qui
  si può assegnare il quartiere per arco più vicino: verificato al **94,9%** di accordo con il
  mapping manuale `mapping/varchi-quartieri.csv` (vedi `notes.md`).
- Una via può stare su due quartieri: chi consuma sceglie (es. il quartiere con più archi).

## Run

```bash
toolkit run --config datasets/rifter-archi/dataset.yml
```

Analisi collegata: `analisi/15_tassi_per_zona.sql` (bici per 1.000 abitanti per zona, passaggi
auto per 1.000 abitanti per quartiere).
