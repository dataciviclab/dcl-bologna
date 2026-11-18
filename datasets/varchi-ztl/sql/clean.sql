-- clean.sql: varchi ZTL — passaggi veicolari dai 80 varchi mergiati
--
-- Il raw è il parquet mergiato dei 80 dataset varco-n-* (multi-anno
-- 2019-2026 in un unico file, 1 riga = 1 varco × 1 ora). Trasformazioni:
--   1. anno derivato da data (dato multi-anno, {year} è solo il run year)
--   2. typing con le macro standard
--   3. dedup per chiave (data, varco) con GROUP BY + max() come GUARDIA:
--      lo script di bootstrap deduplica già il raw (~3817 doppioni, 0.02%);
--      il GROUP BY qui lo difende in modo riproducibile. NON usare
--      ROW_NUMBER() OVER — su 18,6M righe il window esplode la RAM
--      (OOM anche con memory_limit 2GB). GROUP BY: 0.7s.
--   (lon/lat già decodificate dal WKB nello script di merge)
--
--   4. geografia amministrativa (quartiere, zona, area statistica, zona di
--      prossimità) dal civico più vicino: support dataset `rifter-civici`.
--      I varchi non espongono `codvia`, quindi il criterio è la distanza.
--
-- Chiave: (data, varco) unica. primary_key del clean.

WITH punti AS (
    SELECT varco, max(longitudine) AS lon, max(latitudine) AS lat
    FROM raw_input WHERE varco IS NOT NULL
    GROUP BY varco
),
civici AS (
    SELECT quartiere, zona, area_statistica, zona_prossimita, via, civico, lat, lon
    FROM read_parquet('{support.civici.clean}')
    WHERE lat IS NOT NULL AND lon IS NOT NULL
),
vicino AS (
    -- civico più vicino per varco (haversine, raggio 6371 km)
    SELECT
        p.varco,
        c.quartiere, c.zona, c.area_statistica, c.zona_prossimita,
        c.via AS via_civico, c.civico,
        2 * 6371000 * asin(sqrt(
            pow(sin(radians(c.lat - p.lat) / 2), 2)
            + cos(radians(p.lat)) * cos(radians(c.lat))
              * pow(sin(radians(c.lon - p.lon) / 2), 2)
        )) AS distanza_m
    FROM punti p
    CROSS JOIN civici c
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p.varco ORDER BY distanza_m) = 1
)
SELECT
    CAST(EXTRACT(YEAR FROM raw_input.data) AS INTEGER) AS anno,
    CAST(raw_input.data AS TIMESTAMP) AS data,

    cast_int(raw_input.varco) AS varco,
    max(normalize_string(nome_varco)) AS nome_varco,
    max(normalize_string(direzione)) AS direzione,
    max(normalize_string(tipologia_varco)) AS tipologia_varco,
    max(normalize_string(descrizione))    AS descrizione,

    cast_bigint(max(totale_passaggi))      AS totale_passaggi,
    cast_bigint(max(auto_furgoni))         AS auto_furgoni,
    cast_bigint(max(moto_ciclomotori))     AS moto_ciclomotori,
    cast_bigint(max(bus_camion))           AS bus_camion,
    cast_bigint(max(non_classificato))     AS non_classificato,
    cast_bigint(max(sintatticamente_corretta))    AS sintatticamente_corretta,
    cast_bigint(max(lista_bianca_regolare))       AS lista_bianca_regolare,
    cast_bigint(max(lista_bianca_fuori_fascia))   AS lista_bianca_fuori_fascia,
    cast_bigint(max(lista_speciale))       AS lista_speciale,
    cast_bigint(max(lista_nera))           AS lista_nera,
    cast_bigint(max(transito_generico_irregolare)) AS transito_generico_irregolare,
    cast_bigint(max(segnalazioni))         AS segnalazioni,

    cast_double(max(longitudine)) AS longitudine,
    cast_double(max(latitudine))  AS latitudine,

    max(v.quartiere)        AS quartiere,
    max(v.zona)             AS zona,
    max(v.area_statistica)  AS area_statistica,
    max(v.zona_prossimita)  AS zona_prossimita,
    max(v.via_civico)       AS via_civico,
    max(v.civico)           AS civico,
    max(ROUND(v.distanza_m)) AS distanza_civico_m

FROM raw_input
-- Coda 2018: la fonte ha 1 sola ora (2018-12-31 23:00-23:45, 240 righe).
-- Il periodo del dataset parte dal 2019: un "anno 2018" di 1 ora entra
-- nei mart come anno pieno (giorni_rilevati=1, passaggi/giorno falsati).
LEFT JOIN vicino v ON cast_int(raw_input.varco) = v.varco
WHERE CAST(raw_input.data AS TIMESTAMP) >= TIMESTAMP '2019-01-01'
GROUP BY raw_input.data, raw_input.varco
