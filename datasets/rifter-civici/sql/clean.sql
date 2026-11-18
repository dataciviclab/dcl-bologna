-- clean.sql: RIFTER — civici (fedele alla fonte)
--
-- Convenzione del repo: il clean è FEDELE alla fonte (rinomine, tipi,
-- normalizzazioni), i mart sono le viste con quello che serve.
-- Quindi qui restano tutte le colonne della fonte; l'unica esclusa è
-- dichiarata in fondo al file.
--
-- Coordinate senza estensione spatial: `CAST(geo_point_2d AS VARCHAR)` rende il
-- WKT ("POINT (lon lat)") e lon/lat si estraggono con una regex.

SELECT
    CAST({year} AS INTEGER) AS anno_run,

    -- identificativi del civico
    normalize_string(civkey) AS civkey,
    cast_int(id_civ) AS id_civ,
    normalize_string(partkey) AS partkey,
    cast_int(codvia) AS codvia,
    cast_int(civico) AS civico,
    normalize_string(subciv) AS subciv,
    normalize_string(ncivsub) AS ncivsub,
    normalize_string(indirizzo_completo) AS indirizzo_completo,

    -- toponomastica e geografia amministrativa
    normalize_string(denominazi) AS via,
    normalize_string(cap) AS cap,
    normalize_string(quartiere) AS quartiere,
    normalize_string(zona) AS zona_codice,
    normalize_string(zona_nome) AS zona,
    normalize_string(area_stati) AS area_statistica,
    cast_int(cod_areast) AS cod_area_statistica,
    normalize_string(zona_pross) AS zona_prossimita,
    normalize_string(centro_sto) AS centro_storico,
    normalize_string(loc_istat) AS localita_istat,
    cast_int(cod_loc_is) AS cod_localita_istat,

    -- sezioni di censimento e bacini (chiavi di join con dati ISTAT/scuole)
    cast_bigint(sez_istat) AS sezione_istat,
    cast_bigint(sez_2011_i) AS sez_2011,
    cast_bigint(sez_2001_i) AS sez_2001,
    cast_bigint(sez_1991_i) AS sez_1991,
    cast_bigint(sez_1981_i) AS sez_1981,
    normalize_string(bacino_scu) AS bacino_scuola,
    normalize_string(bacino_sc0) AS bacino_scuola_0,
    normalize_string(bacino_sc1) AS bacino_scuola_1,

    -- edificio e arco (chiavi di join con RIFTER)
    cast_bigint(codfab) AS codfab,
    cast_int(codarco) AS codarco,
    cast_bigint(codice_ann) AS codice_ann,
    cast_bigint(codice_ans) AS codice_ans,

    -- date di istituzione/variazione del civico
    CAST(data_istit AS DATE) AS data_istituzione,
    CAST(data_varia AS DATE) AS data_variazione,

    -- coordinate: WKT -> DOUBLE (niente spatial)
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 2)) AS lat,
    cast_double(regexp_extract(CAST(geo_point_2d AS VARCHAR), 'POINT \(([-0-9.]+) ([-0-9.]+)\)', 1)) AS lon,
    cast_double(x_utm_etrs) AS x_utm,
    cast_double(y_utm_etrs) AS y_utm
FROM raw_input
WHERE civkey IS NOT NULL

-- ESCLUSA: `geo_shape` (GEOMETRY, GeoJSON della particella). Non è utilizzabile
-- senza l'estensione spatial, pesa ~10x il resto e la geometria del civico non
-- serve a nessun consumer (per la posizione bastano lat/lon).
