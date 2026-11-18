# rifter-civici — numeri civici con geografia amministrativa

**Domanda civica**: come si assegna un punto della città (una colonnina, una centralina, un varco) al suo quartiere, zona e area statistica senza costruire una mappa a mano?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Regioni e città
- **Dataset ODS**: `rifter_civici_pt` — export parquet
- **Granularità**: civico (77.618 righe, 1.774 vie, 18 zone, 90 aree statistiche, 6 quartieri)
- **Periodo**: snapshot della numerazione civica
- **Chiave**: `civkey` (unico su tutte le righe)

## Perché vale la pena

È il **backbone di join** del repo. Ogni civico porta:

| Colonna | Contenuto |
|---|---|
| `quartiere` | uno dei 6 quartieri |
| `zona` | una delle 18 zone statistiche (es. "Costa Saragozza") |
| `area_statistica` | una delle 90 aree (es. "IRNERIO-2") |
| `zona_prossimita` | zona di prossimità (es. "Pontevecchio - Mazzini") |
| `bacino_scuola` | bacino scolastico |
| `lat`/`lon` | coordinate (dal WKT, senza estensione spatial) |

Con il **civico più vicino** si assegna la geografia a qualunque punto. È così che
`colonnine-bici` ha smesso di usare un CSV di mapping: 24/24 quartieri e 24/24 zone identici,
distanza mediana 21 m.

## Output

| Mart | Contenuto |
|---|---|
| `mart_zona_civici` | per quartiere × zona: civici, vie, aree statistiche, bounds delle coordinate |

## Limiti

- **È uno snapshot**: se cambia la numerazione civica va rigenerato.
- **`area_statistica` usa nomi propri** ("IRNERIO-2") che vanno confrontati con quelli di
  `reddito-mediano` e `indici-fragilita` prima di un join: normalizzare con `UPPER(TRIM(...))`.
- **Coordinate dal WKT**: `CAST(geo_point_2d AS VARCHAR)` dà "POINT (lon lat)". Se un giorno
  DuckDB cambiasse la resa, il parsing va rivisto (il test è `lat`/`lon` non nulle).

## Run

```bash
toolkit run --config datasets/rifter-civici/dataset.yml
```

Usato come support da: `colonnine-bici`. Pronto per `centraline-aria` e `varchi-ztl`.
