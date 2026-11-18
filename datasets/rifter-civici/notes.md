# notes.md — rifter-civici

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`civkey` è unico** su 77.618 righe: è la chiave, non `codvia`+`civico` (che hanno subalterni).
- **`civico` è DOUBLE** nel parquet (13.0): cast a INTEGER. Può essere assente.
- **`zona` è un codice** (lettera, es. "F"), il nome sta in `zona_nome` → nel clean: `zona_codice` e `zona`.
- **`area_stati`** contiene il nome dell'area statistica ("IRNERIO-2"), non un codice.
- **Geometria**: `geo_point_2d` è GEOMETRY; `CAST(... AS VARCHAR)` dà WKT "POINT (lon lat)" e si
  estraggono lon/lat senza l'estensione `spatial`. `geo_shape` è esclusa.
- **Coordinate nel WKT**: ordine **lon, lat**. Invertirle non dà errore, dà distanze sbagliate.

## Rischi noti

- **Snapshot**: nessuna serie storica della numerazione civica. Se il Comune rinumera, il dataset
  va rigenerato e i join possono spostarsi di un civico.
- **Civico più vicino ≠ civico giusto**: per un punto a metà isolato il vicino può essere
  dall'altra parte della strada. La distanza è esposta (`distanza_civico_m` nel consumer) proprio
  per poterla controllare.
- **Nomi delle aree statistiche**: non garantiti identici a `reddito-mediano` e `indici-fragilita`.
  Il join va fatto con `UPPER(TRIM(...))` e verificato (90 aree qui).

## Decisioni metodologiche

- **Support, non mapping**: il dataset è pensato per essere consumato come `support: type: dataset`,
  con placeholder `{support.civici.clean}`. Il toolkit lo esegue prima del candidate.
- **Clean = lookup**: il clean contiene solo le colonne utili al join (niente campi catastali,
  sezioni ISTAT, UTM), per tenerlo leggero.
- **Nessuna assegnazione nel dataset**: il "civico più vicino" si calcola nel consumer, perché la
  scelta (e la soglia di distanza) dipende dal dato.

## Colonne fuori dal clean (dichiarate)

Convenzione del repo: il clean è **fedele alla fonte** (rinomine, tipi, normalizzazioni),
i mart sono le viste con quello che serve. Restano quindi tutte le colonne della fonte;
l'unica esclusa è dichiarata qui.

| Colonna fonte | Perché è fuori |
|---|---|
| `geo_shape` | GEOMETRY (GeoJSON della particella): non usabile senza l'estensione `spatial`, pesa ~10× il resto, e nessun consumer usa la geometria del civico — per la posizione bastano `lat`/`lon` (dal WKT di `geo_point_2d`) |

Rinomine applicate (nessuna informazione persa): `denominazi` → `via`, `zona_nome` → `zona`,
`zona` → `zona_codice`, `area_stati` → `area_statistica`, `zona_pross` → `zona_prossimita`,
`bacino_scu` → `bacino_scuola`, `data_istit` → `data_istituzione`, `data_varia` → `data_variazione`,
`geo_point_2d` → `lat`/`lon`, `x_utm_etrs`/`y_utm_etrs` → `x_utm`/`y_utm`.
