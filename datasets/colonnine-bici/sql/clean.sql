-- clean.sql: colonnine conta-bici — export unico multi-anno (2018-2026)
--
-- Il raw è un singolo parquet (tutti gli anni). Trasformazioni:
--   1. anno derivato dalla data (il dato è multi-anno, {year} è solo il run year)
--   2. dedup su (data, colonnina): esistono letture ridondanti (~60 coppie,
--      valori diversi es. totale 0 vs 51) → tengo la lettura col totale maggiore
--   3. join con mapping quartieri (mapping/colonnine-quartieri.csv) per
--      arricchire colonnina → quartiere/zona/via
--   4. typing con le macro standard
--
-- Chiave: (data, colonnina) unica dopo dedup. primary_key del clean.

SELECT
    CAST(EXTRACT(YEAR FROM r.data) AS INTEGER) AS anno,
    CAST(r.data AS TIMESTAMP) AS data,

    normalize_string(r.colonnina) AS colonnina,
    normalize_string(m.quartiere) AS quartiere,
    normalize_string(m.zona) AS zona,
    normalize_string(m.via) AS via,

    cast_bigint(r.direzione_centro)    AS direzione_centro,
    cast_bigint(r.direzione_periferia) AS direzione_periferia,
    cast_bigint(r.totale)              AS totale,

    cast_double(m.lon) AS longitudine,
    cast_double(m.lat) AS latitudine

FROM raw_input r
LEFT JOIN read_csv('mapping/colonnine-quartieri.csv',
                   auto_detect=true, delim=',', header=true) m
    ON r.colonnina = m.colonnina

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY r.data, r.colonnina
    ORDER BY r.totale DESC
) = 1
