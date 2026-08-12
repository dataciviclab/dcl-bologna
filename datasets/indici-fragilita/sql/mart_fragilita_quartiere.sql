-- mart_fragilita_quartiere.sql: sintesi di fragilità per quartiere × anno
--
-- Aggrega le aree valide (aree_escl=0) per quartiere e anno: numero di aree,
-- media semplice dei 4 indici sintetici e quota di aree nel cluster di
-- fragilità più alta (cluster_an più alto presente in quell'anno).
--
-- NOTA: media SEMPLICE, non ponderata per pop_res. Il campo pop_res della
-- fonte ha un drift di scala dal 2022 (aree grandi in migliaia, piccole in
-- unità) che renderebbe le medie ponderate false. rmpe_fam escluso: nel 2023
-- la fonte riattiva due aree con unità in euro (non migliaia), quindi non è
-- normalizzabile in modo affidabile (v. notes.md).

WITH base AS (
    SELECT
        anno,
        quartiere,
        area_statistica,
        frag_demo,
        frag_soc,
        frag_econ,
        frag_compl,
        cluster_an
    FROM clean_input
    WHERE aree_escl = 0
      AND quartiere IS NOT NULL AND quartiere <> ''
)
SELECT
    anno,
    quartiere,
    COUNT(DISTINCT area_statistica) AS aree,
    ROUND(AVG(frag_demo), 1)  AS frag_demo_media,
    ROUND(AVG(frag_soc), 1)   AS frag_soc_media,
    ROUND(AVG(frag_econ), 1)  AS frag_econ_media,
    ROUND(AVG(frag_compl), 1) AS frag_compl_media,
    ROUND(100.0 * SUM(CASE WHEN cluster_an = (SELECT MAX(cluster_an) FROM base b2 WHERE b2.anno = base.anno) THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS quota_pct_aree_cluster_alto
FROM base
GROUP BY anno, quartiere
