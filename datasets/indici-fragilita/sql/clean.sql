-- clean.sql: indici di fragilità per area statistica (2021-2023)
--
-- Export unico multi-anno da OpenData Bologna (ODS). Trasformazioni:
--   1. yyyy (DATE nella fonte, es. 2023-01-01) → anno INTEGER via EXTRACT(YEAR)
--      (stesso quirk di popolazione-quartiere: {year} è solo il run year)
--   2. typing esplicito: BIGINT → INTEGER per indici/cluster, DOUBLE per % e reddito
--   3. normalize_string sulle dimensioni testuali
--
-- Chiave unica verificata: (anno, area_statistica). primary_key del clean.
-- Nota: perc_ab_no è interamente NULL nella fonte → escluso dal clean (documentato in notes.md).

SELECT
    CAST(EXTRACT(YEAR FROM yyyy) AS INTEGER) AS anno,

    normalize_string(area_statistica) AS area_statistica,
    normalize_string(quartiere)       AS quartiere,
    normalize_string(zona_pross)      AS zona_pross,

    cast_int(aree_escl) AS aree_escl,
    cast_bigint(pop_res) AS pop_res,

    cast_double(var_5y_pop) AS var_5y_pop,
    cast_double(saldonat)   AS saldonat,
    cast_double(ultra80)    AS ultra80,
    cast_double(soli_65)    AS soli_65,
    cast_double(imem_italia) AS imem_italia,
    cast_double(imem_stra)  AS imem_stra,
    cast_double(stra_0_19)  AS stra_0_19,
    cast_double(minori1gen) AS minori1gen,
    cast_double(perc_laur)  AS perc_laur,
    cast_double(perfragsan) AS perfragsan,
    cast_double(peraffit)   AS peraffit,
    cast_double(rmpe_fam)   AS rmpe_fam,
    cast_double(perfam_r60) AS perfam_r60,
    cast_double(integrazione) AS integrazione,
    cast_double(spazinsuff) AS spazinsuff,
    cast_double(bil)        AS bil,
    cast_double(bqe)        AS bqe,

    cast_int(frag_demo)  AS frag_demo,
    cast_int(frag_soc)   AS frag_soc,
    cast_int(frag_econ)  AS frag_econ,
    cast_int(frag_compl) AS frag_compl,
    cast_int(cluster_an) AS cluster_an,
    cast_int(codareast)  AS codareast

FROM raw_input
