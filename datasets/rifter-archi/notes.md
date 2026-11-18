# notes.md — rifter-archi

Quirk della fonte, rischi noti, decisioni metodologiche.

## Quirk della fonte

- **`codvia` ↔ `codice_via` delle spire**: stesso spazio di codici. Verificato 2026-11-18:
  320 vie distinte delle spire, 320 con match (100%). È il motivo per cui esiste il dataset.
- **Una via su più quartieri**: 120 `codvia` su 1.972 compaiono su più di un quartiere (vie che
  attraversano il confine). La chiave del crosswalk è quindi `(codvia, quartiere)`, non `codvia`.
- **Geometria**: il parquet porta `geo_point_2d` come GEOMETRY e servirebbe l'estensione
  `spatial` per `ST_X`/`ST_Y`. Il **CSV** invece la espone come testo ("44.53, 11.35"):
  la sorgente è quindi il CSV e il clean espone `lat`/`lon` come DOUBLE, senza estensione.
  anche `geo_shape` resta, come WKT (`CAST(geo_shape AS VARCHAR)`): è un LINESTRING, quindi
  informazione non altrimenti disponibile in questo dataset.
- **Unità di misura delle coordinate**: `geo_point_2d` è "lat, lon" — non "lon, lat". Invertirle
  non dà errore, dà distanze sbagliate di migliaia di km: è l'errore da non fare.
- **`civico_min`/`civico_mas`** sono i civici estremi dell'arco: utili per capire il verso, non
  per assegnare un indirizzo (per quello serve `rifter_civici_pt`).

## Rischi noti

- **Il quartiere è quello dell'arco**: se una via è di confine, un punto su quella via può
  ricevere il quartiere sbagliato. Con 120 vie su 1.972 il rischio è limitato ma reale.
- **Snapshot**: se il Comune rinomina una via o cambia i codici, il crosswalk va rigenerato.
  Non c'è una serie storica della toponomastica.
- **`codvia` è un codice numerico**: non va mai unito a una stringa per nome via. Il join corretto
  è sempre sul codice; il nome serve solo a leggere.

## Decisioni metodologiche

- **Solo `mart_via_quartiere` è pensato per il riuso**: `mart_quartiere_archi` è un benchmark
  territoriale (quanta strada per quartiere), non un lookup.
- **Nessun mapping in `mapping/`**: la directory è stata rimossa. La geografia arriva da
  `rifter-civici` (support) e da questo dataset; i dataset che non espongono `codvia` usano
  il civico più vicino.
- **`anno_run` nel clean**: il dataset è uno snapshot, `{year}` è l'anno di esecuzione.

## Esperimento: quartiere per arco più vicino (varchi)

I varchi non hanno `codvia`, quindi il crosswalk per codice non li copre. Test con lat/lon qui:
per ogni varco si prende l'arco più vicino (haversine) e il suo `quartiere`.

| | |
|---|---|
| varchi confrontabili | 79 |
| accordo con il mapping manuale storico | **75/79 = 94,9%** |
| distanza dall'arco più vicino | mediana 15 m, max 81 m |

I 4 disaccordi sono **confini reali**, non errori: via D'Azeglio, via Indipendenza (2 varchi),
viale Ercolani (anello). Entrambe le assegnazioni sono difendibili.

Conclusione: il metodo è pronto per i dataset puntuali senza codice via (varchi, centraline).
Per i varchi non conviene rigenerare il mapping: è già corretto dove conta, e il test lo conferma.

## Colonne fuori dal clean (dichiarate)

Convenzione del repo: clean **fedele alla fonte**, mart come viste. **Nessuna colonna della
fonte è esclusa**: `geo_shape` resta come WKT di linea.

Rinomine (nessuna perdita): `nomevia` → `nome_via`, `nomequart` → `quartiere`,
`numquart` → `num_quartiere`, `lunghez` → `lunghezza_m`, `cod_nodo1/2` → `nodo_da`/`nodo_a`,
`civico_mas` → `civico_max`, `data_istit` → `data_istituzione`, `geo_point_2d` → `lat`/`lon`.

## Snapshot, non serie

Nessun `time_coverage`: è lo **snapshot della rete stradale**. `data_istituzione` degli archi va
dal 1990, ma non è un periodo coperto dal dataset. Dichiararlo come periodo farebbe leggere al
catalogo una serie che non esiste.
