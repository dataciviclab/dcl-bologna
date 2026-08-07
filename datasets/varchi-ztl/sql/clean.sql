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
-- Chiave: (data, varco) unica. primary_key del clean.

SELECT
    CAST(EXTRACT(YEAR FROM data) AS INTEGER) AS anno,
    CAST(data AS TIMESTAMP) AS data,

    cast_int(varco) AS varco,
    max(normalize_string(nome_varco)) AS nome_varco,
    max(normalize_string(direzione)) AS direzione,
    max(normalize_string(tipologia_varco)) AS tipologia_varco,

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
    cast_double(max(latitudine))  AS latitudine

FROM raw_input
GROUP BY data, varco
