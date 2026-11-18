-- clean.sql: RIFTER — civici (numeri civici con geografia amministrativa)
--
-- È il backbone di join del repo: ogni civico porta quartiere, zona,
-- area statistica, zona di prossimità e bacino scolastico. Assegnando un punto
-- (colonnina, centralina, varco) al civico più vicino si ottengono tutte queste
-- dimensioni senza mapping manuali.
--
-- Coordinate senza estensione spatial: `CAST(geo_point_2d AS VARCHAR)` rende il
-- WKT ("POINT (lon lat)"), quindi lon/lat si estraggono con una regex.
-- `geo_shape` è esclusa.

SELECT
    CAST({year} AS INTEGER) AS anno_run,
    normalize_string(civkey) AS civkey,
    cast_int(codvia) AS codvia,
    cast_int(civico) AS civico,
    normalize_string(subciv) AS subciv,
    normalize_string(denominazi) AS via,
    normalize_string(quartiere) AS quartiere,
    normalize_string(zona) AS zona_codice,
    normalize_string(zona_nome) AS zona,
    normalize_string(area_stati) AS area_statistica,
    normalize_string(zona_pross) AS zona_prossimita,
    normalize_string(bacino_scu) AS bacino_scuola,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2)) AS lat,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1)) AS lon
FROM raw_input
WHERE civkey IS NOT NULL
