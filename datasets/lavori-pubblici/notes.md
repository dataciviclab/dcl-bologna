# notes.md — lavori-pubblici

Quirk della fonte, rischi noti, decisioni metodologiche.

## Architettura (due fonti, schema identico)

- Due dataset ODS separati — `lavori-pubblici-storico` (conclusi) e `lavori-pubblici` (in corso) — con **schema identico**. Si uniscono con `clean.read.mode: all`; la provenienza per riga arriva da `inject_column: {origine: …}` per fonte (`storico` / `in_corso`), **non** derivata dallo `status` (che resta un dato della fonte).
- Caso opposto a `centraline-aria`, dove i due raw hanno schema diverso e `inject_column` non si può usare (UNION posizionale). Qui lo schema è lo stesso, quindi `inject_column` è lo strumento corretto.

## Trappole verificate

- **FUSO ORARIO (off-by-one su tutte le righe)**. I timestamp sono istanti corretti con mezzanotte **locale**: `22:00Z` d'estate, `23:00Z` d'inverno. `CAST(ts AS DATE)` usa UTC (DuckDB default) e sbaglia di un giorno su **1.813/1.813** righe. La data locale è `CAST(ts AT TIME ZONE 'Europe/Rome' AS DATE)`. Prova riproducibile: coi timestamp come UTC i cantieri partirebbero di **domenica**; in ora locale **967/1.813 partono di lunedì**. (A differenza di `varchi`/`spire`, qui l'istante è corretto — non è etichettato male.)
- **`id` NON è un id di riga**: è un id di **lavoro/lotto**. Nello storico 1.779 righe ma 1.699 `id` distinti (75 id ripetuti, fino a 4 fasi). Le righe di uno stesso `id` differiscono per date/geometria/testo: non sono doppioni da scartare, sono fasi. **Nessuna riga è duplicata su tutte le colonne.**
- **`roadway1/2/3` NON sono le vie**: sono il **tipo di sede** ("Strada bitumata", "Marciapiede bitumato", "Ponte"). La via è `address` → `via`.
- **`neighborhood1` È il quartiere** (i 6 quartieri, es. "Porto - Saragozza"): popolato su 1.648/1.779 dello storico. `neighborhood2/3` sono quasi sempre vuoti (4 e 1). Correzione a una lettura iniziale affrettata ("quartieri quasi tutti null").
- **`year` ≠ anno della data**: `year` è un marcatore di anno di programmazione (DATE al 1° gennaio); diverge dall'anno di `data_inizio` su ~100 righe. Tenuti entrambi (`anno_pianificato`, `anno_inizio`).
- **`trafficchangesmeasure` è testo libero**: almeno 4 varianti di "Restringimenti di carreggiata", più chiusure, senso unico, sosta, "non sono previste modifiche". 36 righe vuote (storico). Molti testi sono **combinati** ("Restringimento … e chiusura del marciapiede"): 60 citano sia chiusura sia restringimento.

## Decisioni metodologiche

- **`row_id` = md5 delle colonne identificative** (pattern di `akn-relations`). Il dataset non ha chiave naturale e — per non perdere righe — si tiene una riga per fase così com'è nella fonte. `row_id` è deterministico e unico (1.813/1.813).
- **`impatto_categoria`** è una **normalizzazione dichiarata** del testo libero (normalizzazioni ammesse nel clean): priorità unica dal più severo, `chiusura → divieto_transito → senso_unico → restringimento → divieto_sosta → nessuna_modifica → altro → non_dichiarato`. Il testo originale resta in `impatto_traffico` per la lettura fine.
- **Date in ora locale** in tutta la pipeline (`data_inizio`, `data_fine`).
- **Lavori in corso** con `data_fine` NULL (24 righe): nei mart si considerano attivi fino all'ultimo mese noto del dataset (non oltre). Approssimazione dichiarata. Le altre 10 hanno una `data_fine` **pianificata** (fino al 2028): di conseguenza il mart arriva al 2028 e va limitato agli anni osservati nei trend (lo fa `analisi/16`).
- **`time_coverage` 2021–2026**: allineato al campo `year` della fonte. 3 lavori del programma 2021 hanno `data_inizio` a fine 2020 (preparazione) e restano nel dataset: hanno durate reali, non creano "anni da 1 giorno".

## Query di verifica

Le date in ora locale (conteggio off-by-one e giorno della settimana):

```sql
SELECT
  count(*) FILTER (WHERE CAST(effectivestartdate AS DATE)
                     <> CAST(effectivestartdate AT TIME ZONE 'Europe/Rome' AS DATE)) AS off_by_one,
  count(*) FILTER (WHERE dayname(CAST(effectivestartdate AT TIME ZONE 'Europe/Rome' AS DATE)) = 'Monday') AS lunedi
FROM read_parquet('out/data/clean/lavori_pubblici/2026/lavori_pubblici_2026_clean.parquet');
```

L'incrocio della tabella in README (Via Stalingrado, spire × `mart_cantiere_via_mese`; le spire sono multi-anno in `out/data/clean/spire_traffico/*/`):

```sql
WITH sm AS (
  SELECT nome_via AS via, strftime(data,'%Y-%m') AS mese,
         CAST(strftime(data,'%Y') AS INT) AS anno, CAST(strftime(data,'%m') AS INT) AS mm,
         SUM(passaggi) * 1.0 / COUNT(DISTINCT data) AS passaggi_giorno
  FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet')
  GROUP BY 1,2,3,4
)
SELECT sm.mese, ROUND(sm.passaggi_giorno) AS passaggi_giorno,
       COALESCE(cm.cantieri_attivi,0) AS cantieri,
       COALESCE(cm.cantieri_chiusura,0) AS chiusura,
       COALESCE(cm.cantieri_restringimento,0) AS restringimento
FROM sm
LEFT JOIN read_parquet('out/data/mart/lavori_pubblici/2026/mart_cantiere_via_mese.parquet') cm
  ON cm.via = sm.via AND cm.anno = sm.anno AND cm.mese = sm.mm
WHERE sm.via = 'VIA STALINGRADO' AND sm.mese >= '2023-06' AND sm.mm IN (1,3,6,8,10,12)
ORDER BY sm.mese;
```

Copertura del join con le spire e confronto anni (via × mese):

```sql
WITH cv AS (SELECT DISTINCT via FROM read_parquet('out/data/clean/lavori_pubblici/2026/lavori_pubblici_2026_clean.parquet')),
     sv AS (SELECT DISTINCT UPPER(TRIM(nome_via)) AS via
            FROM read_parquet('out/data/clean/spire_traffico/*/spire_traffico_*_clean.parquet'))
SELECT (SELECT count(*) FROM cv) AS vie_cantieri, (SELECT count(*) FROM sv) AS vie_spire,
       (SELECT count(*) FROM cv JOIN sv USING(via)) AS comuni;
-- 745 vie cantieri · 329 vie spire · 230 comuni (29%)
```

## Colonne fuori dal clean (dichiarate)

Nessuna: tutte le 20 colonne della fonte sono nel clean (rinominate in italiano, mappatura nel header di `sql/clean.sql`). Le 3 geometrie restano come WKT (`pinpoint_wkt`, `civico_da_wkt`, `civico_a_wkt`), più le coordinate estratte (`longitudine`/`latitudine`) — senza estensione spatial.

## Trappola da non ripetere

I numeri di San Donato citati in una sessione precedente (traffico da 200.709 a 60.378) **non si riproducono**: la serie spire per `VIA SAN DONATO` sta su valori ~16.000–24.000 passaggi/giorno. Probabile errore di aggregazione a monte (somma senza dividere per i giorni, o via sbagliata). Nel README si usa solo Stalingrado, che riproduce esattamente. Da ricontrollare se si riprende il caso San Donato.
