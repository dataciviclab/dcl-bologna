-- clean.sql: lavori pubblici / cantieri stradali del Comune di Bologna
--
-- Due raw con schema IDENTICO nella stessa view (clean.read.mode: "all"):
--   A) lavori-pubblici-storico  → lavori conclusi (1.779 righe, 2021-2026)
--   B) lavori-pubblici          → lavori in corso (34 righe, snapshot)
-- La provenienza per riga è la colonna `origine` iniettata per fonte
-- (inject_column nel dataset.yml): 'storico' / 'in_corso'. Non è derivata
-- dallo `status`, che resta un dato della fonte.
--
-- Convenzione del repo: il clean è FEDELE alla fonte (rinomine, tipi,
-- normalizzazioni), i mart sono le viste. Qui: rinominiamo le colonne in
-- italiano leggibile (mappatura nel commento), tipizziamo, portiamo le date
-- in ora locale, estraiamo le coordinate dal WKT e normalizziamo il campo
-- libero dell'impatto in una categoria (vedi `impatto_categoria`).
--
-- Trappole verificate (dettaglio e query in notes.md):
--   1. FUSO: i timestamp sono istanti corretti con mezzanotte LOCALE
--      (22:00Z d'estate, 23:00Z d'inverno). CAST(ts AS DATE) usa UTC e
--      sbaglia di un giorno su TUTTE le 1.813 righe. La data locale è
--      CAST(ts AT TIME ZONE 'Europe/Rome' AS DATE).
--   2. `id` NON è un id di riga: è un id di lavoro/lotto che si ripete su
--      più fasi (e su righe quasi-duplicate). Non è usabile come chiave.
--   3. `roadway1/2/3` NON sono le vie: sono il tipo di sede ("Strada
--      bitumata", "Ponte"). La via è `address` → `via`.
--   4. `neighborhood1` È il quartiere (6 valori); `neighborhood2/3` sono
--      quasi sempre vuoti.
--
-- Chiave: `row_id` = md5 delle colonne identificative. Il dataset non ha una
-- chiave naturale: ogni riga è identica alla fonte e `row_id` la identifica
-- in modo deterministico (precedente: akn-relations, che usa lo stesso pattern).
--
-- Mappatura nomi fonte → clean:
--   address                    → via
--   description                → descrizione
--   trafficchangesmeasure      → impatto_traffico  (+ impatto_categoria)
--   effectivestartdate         → data_inizio
--   effectiveenddate           → data_fine
--   year                       → anno_pianificato
--   roadway1/2/3               → tipo_sede_1/2/3
--   neighborhood1/2/3          → quartiere / quartiere_2 / quartiere_3
--   addressnumberfrom/to       → civico_da / civico_a
--   pinpoint                   → pinpoint_wkt (+ longitudine/latitudine)
--   addressnumberfrom/to…      → civico_da_wkt / civico_a_wkt

WITH base AS (
    SELECT
        cast_bigint(id)                       AS id,
        normalize_string(origine)             AS origine,
        normalize_string(status)              AS status,

        -- la via (senza civico): le coordinate/civici stanno nei campi a parte
        normalize_string(address)             AS via,
        normalize_string(description)         AS descrizione,
        normalize_string(trafficchangesmeasure) AS impatto_traffico,

        -- Categoria normalizzata dal testo libero (almeno 4 varianti di
        -- "Restringimenti di carreggiata" + chiusure + sosta + senso unico).
        -- Priorità unica, dal più al meno impattante sulla carreggiata.
        -- NOTA: i testi possono essere COMBINATI ("Restringimento … e
        -- chiusura del marciapiede"): 60 testi citano sia chiusura sia
        -- restringimento. La categoria prende il primo match in quest'ordine;
        -- il testo originale resta in `impatto_traffico` per la lettura fine.
        CASE
            WHEN normalize_string(trafficchangesmeasure) IS NULL THEN 'non_dichiarato'
            WHEN lower(trafficchangesmeasure) LIKE '%chius%'          THEN 'chiusura'
            WHEN lower(trafficchangesmeasure) LIKE '%divieto di transito%'
              OR lower(trafficchangesmeasure) LIKE '%interruzion%'    THEN 'divieto_transito'
            WHEN lower(trafficchangesmeasure) LIKE '%senso unico%'    THEN 'senso_unico'
            WHEN lower(trafficchangesmeasure) LIKE '%restringiment%'  THEN 'restringimento'
            WHEN lower(trafficchangesmeasure) LIKE '%sosta%'          THEN 'divieto_sosta'
            WHEN lower(trafficchangesmeasure) LIKE '%non sono previste%'
              OR lower(trafficchangesmeasure) LIKE '%nessuna modifica%' THEN 'nessuna_modifica'
            ELSE 'altro'
        END                                   AS impatto_categoria,

        -- Date in ORA LOCALE (vedi trappola 1)
        CAST(effectivestartdate AT TIME ZONE 'Europe/Rome' AS DATE) AS data_inizio,
        CAST(effectiveenddate   AT TIME ZONE 'Europe/Rome' AS DATE) AS data_fine,
        -- `year` della fonte è un marcatore di anno di programmazione (DATE al
        -- 1° gennaio), non l'anno della data di inizio: le due cose divergono
        -- su ~100 righe. Teniamo entrambe.
        CAST(EXTRACT(YEAR FROM CAST(year AS DATE)) AS INTEGER)      AS anno_pianificato,

        normalize_string(roadway1)            AS tipo_sede_1,
        normalize_string(roadway2)            AS tipo_sede_2,
        normalize_string(roadway3)            AS tipo_sede_3,
        normalize_string(neighborhood1)       AS quartiere,
        normalize_string(neighborhood2)       AS quartiere_2,
        normalize_string(neighborhood3)       AS quartiere_3,
        normalize_string(addressnumberfrom)   AS civico_da,
        normalize_string(addressnumberto)     AS civico_a,

        -- geometrie come WKT (senza estensione spatial): CAST(… AS VARCHAR)
        CAST(pinpoint AS VARCHAR)                        AS pinpoint_wkt,
        CAST(addressnumberfromcoordinate AS VARCHAR)     AS civico_da_wkt,
        CAST(addressnumbertocoordinate AS VARCHAR)       AS civico_a_wkt
    FROM raw_input
)
SELECT
    md5(
        COALESCE(CAST(id AS VARCHAR), '')       || '|' ||
        COALESCE(origine, '')                   || '|' ||
        COALESCE(status, '')                    || '|' ||
        COALESCE(via, '')                       || '|' ||
        COALESCE(descrizione, '')               || '|' ||
        COALESCE(impatto_traffico, '')          || '|' ||
        COALESCE(CAST(data_inizio AS VARCHAR), '') || '|' ||
        COALESCE(CAST(data_fine AS VARCHAR), '')   || '|' ||
        COALESCE(CAST(anno_pianificato AS VARCHAR), '') || '|' ||
        COALESCE(tipo_sede_1, '') || '|' || COALESCE(tipo_sede_2, '') || '|' ||
        COALESCE(tipo_sede_3, '') || '|' ||
        COALESCE(quartiere, '')  || '|' || COALESCE(quartiere_2, '') || '|' ||
        COALESCE(quartiere_3, '') || '|' ||
        COALESCE(civico_da, '')  || '|' || COALESCE(civico_a, '') || '|' ||
        COALESCE(pinpoint_wkt, '') || '|' || COALESCE(civico_da_wkt, '') || '|' ||
        COALESCE(civico_a_wkt, '')
    )                                            AS row_id,
    id,
    origine,
    status,
    via,
    descrizione,
    impatto_traffico,
    impatto_categoria,
    data_inizio,
    data_fine,
    anno_pianificato,
    CAST(EXTRACT(YEAR FROM data_inizio) AS INTEGER) AS anno_inizio,
    tipo_sede_1,
    tipo_sede_2,
    tipo_sede_3,
    quartiere,
    quartiere_2,
    quartiere_3,
    civico_da,
    civico_a,
    -- coordinate del punto (WKT "POINT (lon lat)"), come per i varchi
    cast_double(regexp_extract(pinpoint_wkt, 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1)) AS longitudine,
    cast_double(regexp_extract(pinpoint_wkt, 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2)) AS latitudine,
    pinpoint_wkt,
    civico_da_wkt,
    civico_a_wkt
FROM base
-- Nessuna colonna della fonte è esclusa: tutte le 20 colonne del raw sono qui,
-- con i nomi rinominati (mappatura sopra) e le 3 geometrie rese in WKT.
