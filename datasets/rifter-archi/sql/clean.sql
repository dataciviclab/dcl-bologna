-- clean.sql: RIFTER — archi stradali (fedele alla fonte)
--
-- Convenzione del repo: clean FEDELE alla fonte, mart come viste. Qui restano
-- tutte le colonne; l'unica esclusa è dichiarata in fondo.
--
-- Serve a dare un quartiere a chi espone un codice via: `codvia` è la chiave di
-- join verso le spire (`codice_via`), copertura 100% su 320 vie.
--
-- Coordinate senza estensione spatial: `CAST(geo_point_2d AS VARCHAR)` rende il
-- WKT ("POINT (lon lat)") e lon/lat si estraggono con una regex.

SELECT
    CAST({year} AS INTEGER) AS anno_run,
    cast_int(codarco) AS codarco,
    cast_int(codvia) AS codvia,
    normalize_string(nomevia) AS nome_via,
    normalize_string(nomequart) AS quartiere,
    cast_int(numquart) AS num_quartiere,
    cast_double(lunghez) AS lunghezza_m,
    normalize_string(da) AS da_via,
    normalize_string(a) AS a_via,
    cast_int(cod_nodo1) AS nodo_da,
    cast_int(cod_nodo2) AS nodo_a,

    -- civici dell'arco: minimo, massimo e varianti (esponenti e civici misti)
    cast_int(civico_min) AS civico_min,
    cast_int(civico_mas) AS civico_max,
    normalize_string(esponente) AS esponente_min,
    normalize_string(esponente0) AS esponente_max,
    normalize_string(esponente1) AS esponente_1,
    normalize_string(esponente2) AS esponente_2,
    cast_int(civico_mi0) AS civico_min_0,
    cast_int(civico_ma0) AS civico_max_0,

    CAST(data_istit AS DATE) AS data_istituzione,
    cast_bigint(codice_ans) AS codice_ans,

    -- coordinate: WKT -> DOUBLE (niente spatial)
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2)) AS lat,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1)) AS lon
FROM raw_input
WHERE codarco IS NOT NULL AND codvia IS NOT NULL

-- ESCLUSA: `geo_shape` (GEOMETRY, LineString dell'arco). Non utilizzabile senza
-- l'estensione spatial e inutilizzata da ogni consumer attuale: gli archi
-- servono per il quartiere e per la lunghezza, non per la geometria di linea.
