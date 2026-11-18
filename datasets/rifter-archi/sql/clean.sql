-- clean.sql: RIFTER — archi stradali di Bologna (rete stradale + toponomastica)
--
-- Serve a dare un quartiere a qualsiasi via senza mapping manuale: ogni arco
-- porta `codvia` e `nomequart`, quindi `codvia` è la chiave di join verso i
-- dataset che espongono il codice via (spire: `codice_via`, copertura 100%
-- su 362 vie, verificata 2026-11-18).
--
-- Coordinate senza estensione spatial: `CAST(geo_point_2d AS VARCHAR)` rende il
-- WKT ("POINT (lon lat)"), quindi lon/lat si estraggono con una regex. ST_X/ST_Y
-- richiederebbero l'estensione spatial; questa via no. `geo_shape` è esclusa.

SELECT
    CAST({year} AS INTEGER) AS anno_run,
    cast_int(codarco) AS codarco,
    cast_int(codvia) AS codvia,
    normalize_string(nomevia) AS nome_via,
    normalize_string(nomequart) AS quartiere,
    cast_int(numquart) AS num_quartiere,
    cast_double(lunghez) AS lunghezza_m,
    cast_int(civico_min) AS civico_min,
    cast_int(civico_mas) AS civico_max,
    normalize_string(da) AS da_via,
    normalize_string(a) AS a_via,
    cast_int(cod_nodo1) AS nodo_da,
    cast_int(cod_nodo2) AS nodo_a,
    normalize_string(codice_ans) AS codice_ans,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2)) AS lat,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1)) AS lon
FROM raw_input
WHERE codarco IS NOT NULL AND codvia IS NOT NULL
