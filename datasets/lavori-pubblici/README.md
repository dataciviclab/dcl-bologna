# lavori-pubblici — cantieri stradali con impatto dichiarato sul traffico

**Domanda civica**: il calo del traffico su alcune arterie è dovuto ai cantieri? E quali vie sono più cantierate, quando e con che impatto sulla circolazione?

## Dataset / fonte

- **Fonte**: [OpenData Comune di Bologna](https://opendata.comune.bologna.it) — tema Trasporti
- **Dataset ODS**:
  - `lavori-pubblici-storico` — lavori conclusi (1.779 righe, 2021–2026) → `origine = 'storico'`
  - `lavori-pubblici` — lavori in corso (34 righe, snapshot) → `origine = 'in_corso'`
- **Granularità**: una riga per **fase dichiarata** di un lavoro (via + date + impatto). Non è una riga per cantiere fisico: lo stesso `id` di lavoro può comparire su più fasi.
- **Periodo**: 2021–2026 (`data_inizio` reale dal 2020-10: 3 lavori del programma 2021 partono a fine 2020)
- **Chiave**: `row_id` (md5 delle colonne identificative) — vedi [Limiti](#limiti)

## Perché vale la pena

È il tassello che manca per verificare (invece di ipotizzare) l'effetto dei cantieri sul traffico:

| Colonna | Contenuto |
|---|---|
| `via` | la via interessata ("VIA STALINGRADO") — senza civico |
| `data_inizio` / `data_fine` | date del cantiere (in **ora locale**, vedi [notes.md](notes.md)) |
| `impatto_traffico` | **impatto dichiarato** sul traffico, testo libero della fonte |
| `impatto_categoria` | stessa informazione normalizzata (chiusura, restringimento, senso unico, …) |
| `quartiere` | quartiere (`neighborhood1` della fonte) |
| `descrizione`, `tipo_sede_*`, `civico_*`, coordinate | dettaglio e geografia |

Si incrocia con **spire** (traffico per via), **varchi ZTL**, **bici** e — tramite `via`/quartiere — con il resto del repo.

### Esempio d'uso verificato: Via Stalingrado

Cantieri reali incrociati con le spire (passaggi/giorno, media mensile):

| Mese | Passaggi/giorno | Cantieri attivi | di cui chiusura | di cui restringimento |
|---|---:|---:|---:|---:|
| 2024-01 (prima) | 146.674 | 0 | 0 | 0 |
| 2024-03 (avvio lavori) | 113.827 | 2 | 0 | 2 |
| 2024-08 | 64.498 | 2 | 0 | 2 |
| 2025-06 | 90.311 | 3 | 1 | 2 |
| 2025-08 (chiusura totale) | 42.976 | 2 | 1 | 1 |
| 2026-03 | 125.442 | 1 | 0 | 1 |
| 2026-10 | 140.119 | 1 | 0 | 1 |

Il calo parte con i lavori e il recupero arriva (pur con un lavoro ancora dichiarato in corso) — coerente con la correzione "non è un calo diffuso, sono cantieri su poche arterie" (discussion #29). La query che produce questa tabella è in [notes.md](notes.md).

## Output

| Mart | Granularità | Contenuto |
|---|---|---|
| `mart_cantiere_via_mese` | via × anno × mese | cantieri attivi, di cui con impatto sulla carreggiata / chiusura / restringimento / senza impatto, cantieri iniziati |
| `mart_cantiere_via` | via | cantieri, fasi distinte, impatto sulla carreggiata, prima data, ultima data attiva (cappata a oggi) e ultima **pianificata**, mesi con cantiere, coordinate |

`mart_cantiere_via_mese` è la vista per l'incrocio temporale con le serie del traffico: "attivo nel mese m" = intervallo `[data_inizio, data_fine]` che interseca `m`.

## Limiti

- **Nessuna chiave naturale**: `id` è un id di **lavoro/lotto** che si ripete su più fasi e su righe quasi-duplicate (differiscono solo per la geometria). Serve `row_id` (md5). Sull'incrocio, conta le righe o `COUNT(DISTINCT id)` a seconda della domanda.
- **Quirk della fonte**: 3 righe hanno `data_fine < data_inizio` (nei mart l'intervallo è normalizzato almeno al mese di inizio); 10 `id` compaiono in entrambe le fonti (storico "Completato" + in corso) e `cantieri_attivi` li conta due volte nei mesi sovrapposti — `lavori_distinti` li conta una volta.
- **`impatto_categoria` è una normalizzazione** del testo libero (almeno 4 varianti di "Restringimenti di carreggiata"). I testi possono essere **combinati**: 60 citano sia chiusura sia restringimento e la categoria prende il match più severo. Il testo originale resta in `impatto_traffico`.
- **Il join con le spire copre 230 vie**: 230/745 vie cantierate (**31%**) = 230/329 vie misurate dalle spire (**70%**). `via` è il nome normalizzato della fonte (maiuscolo, senza civico).
- **Geometria parziale**: 1.301/1.813 righe hanno coordinate (`longitudine`/`latitudine`); le altre hanno il civico testuale.
- **Lavori in corso** (34 righe): `data_fine` NULL per 24. Nei mart si considerano attivi **fino al mese corrente** (data di run), non fino alle date pianificate più lontane.

## Run

```bash
toolkit run --config datasets/lavori-pubblici/dataset.yml
```
