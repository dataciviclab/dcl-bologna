-- clean.sql: colonnine conta-bici — export unico multi-anno (2018-2026)
--
-- Il raw è un singolo parquet (tutti gli anni). Trasformazioni:
--   1. anno derivato dalla data (il dato è multi-anno, {year} è solo il run year)
--   2. dedup su (data, colonnina): esistono letture ridondanti (~60 coppie,
--      valori diversi es. totale 0 vs 51) → tengo la lettura col totale maggiore
--   3. join con mapping quartieri (support type file, ADR-005) per
--      arricchire colonnina → quartiere/zona/via — {support.colonnina_quartieri.path}
--   4. typing con le macro standard
--   5. quartiere/zona/area statistica dal civico piu' vicino (support dataset
--      `rifter_civici`), non piu' da mapping/colonnine-quartieri.csv
--
-- Chiave: (data, colonnina) unica dopo dedup. primary_key del clean.

WITH punti AS (
    -- coordinate della colonnina: il raw ha geo_point_2d GEOMETRY, che resa a
    -- VARCHAR diventa WKT "POINT (lon lat)" — nessuna estensione spatial
    SELECT
        normalize_string(colonnina) AS colonnina,
        max(cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR),
            'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1))) AS lon,
        max(cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR),
            'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2))) AS lat
    FROM raw_input
    WHERE colonnina IS NOT NULL
    GROUP BY 1
),
civici AS (
    SELECT quartiere, zona, area_statistica, zona_prossimita, via, civico, lat, lon
    FROM read_parquet('{support.civici.clean}')
    WHERE lat IS NOT NULL AND lon IS NOT NULL
),
vicino AS (
    -- civico piu' vicino per ogni colonnina (haversine, raggio 6371 km)
    SELECT
        p.colonnina,
        c.quartiere,
        c.zona,
        c.area_statistica,
        c.zona_prossimita,
        c.via,
        c.civico,
        2 * 6371000 * asin(sqrt(
            pow(sin(radians(c.lat - p.lat) / 2), 2)
            + cos(radians(p.lat)) * cos(radians(c.lat))
              * pow(sin(radians(c.lon - p.lon) / 2), 2)
        )) AS distanza_m
    FROM punti p
    CROSS JOIN civici c
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p.colonnina ORDER BY distanza_m) = 1
)

SELECT
    CAST(EXTRACT(YEAR FROM r.data) AS INTEGER) AS anno,
    CAST(r.data AS TIMESTAMP) AS data,

    normalize_string(r.colonnina) AS colonnina,
    normalize_string(v.quartiere) AS quartiere,
    normalize_string(v.zona) AS zona,
    normalize_string(v.area_statistica) AS area_statistica,
    normalize_string(v.zona_prossimita) AS zona_prossimita,
    normalize_string(v.via) AS via,
    v.civico AS civico,
    ROUND(v.distanza_m) AS distanza_civico_m,

    cast_bigint(r.direzione_centro)    AS direzione_centro,
    cast_bigint(r.direzione_periferia) AS direzione_periferia,
    cast_bigint(r.totale)              AS totale,

    p.lon AS longitudine,
    p.lat AS latitudine

FROM raw_input r
LEFT JOIN vicino v ON normalize_string(r.colonnina) = v.colonnina
LEFT JOIN punti p ON normalize_string(r.colonnina) = p.colonnina

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY r.data, r.colonnina
    ORDER BY r.totale DESC
) = 1
