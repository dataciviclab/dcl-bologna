-- clean.sql: RIFTER — archi stradali di Bologna (rete stradale + toponomastica)
--
-- Serve a dare un quartiere a qualsiasi via senza mapping manuale: ogni arco
-- porta `codvia` e `nomequart`, quindi `codvia` è la chiave di join verso i
-- dataset che espongono il codice via (spire: `codice_via`, copertura 100%
-- su 362 vie, verificata 2026-11-18).
--
-- Coordinate: il raw è il **CSV**, dove `geo_point_2d` è testo ("44.53, 11.35").
-- Così si espongono lat/lon come DOUBLE senza l'estensione spatial (che servirebbe
-- per ST_X/ST_Y sul parquet). `geo_shape` (GeoJSON) è esclusa: non serve al
-- crosswalk e pesa.

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
    cast_double(trim(split_part(geo_point_2d, ',', 1))) AS lat,
    cast_double(trim(split_part(geo_point_2d, ',', 2))) AS lon
FROM raw_input
WHERE codarco IS NOT NULL AND codvia IS NOT NULL
