-- mart_fragilita_area.sql: indici di fragilità per area statistica × anno
--
-- Snapshot analitico per area (aree_escl=0 escluse: ospedali, parchi, zone
-- industriali dove gli indici non sono calcolati dalla fonte). Benchmark:
-- posizione dell'area nel comune (rank) per ciascun indice sintetico.
--
-- NOTA: pop_res e rmpe_fam NON sono nel mart (v. notes.md — drift di scala
-- nella fonte dal 2022, non normalizzabile in modo affidabile). Restano nel
-- clean ma non sono confrontabili cross-anno. Il mart usa solo gli indici
-- sintetici, stabili tra anni.

WITH base AS (
    SELECT
        anno,
        area_statistica,
        quartiere,
        zona_pross,
        frag_demo,
        frag_soc,
        frag_econ,
        frag_compl,
        cluster_an,
        peraffit,
        soli_65,
        perc_laur
    FROM clean_input
    WHERE aree_escl = 0
      AND area_statistica IS NOT NULL AND area_statistica <> ''
)
SELECT
    anno,
    area_statistica,
    quartiere,
    zona_pross,
    frag_demo,
    frag_soc,
    frag_econ,
    frag_compl,
    cluster_an,
    peraffit,
    soli_65,
    perc_laur,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY frag_demo)  AS rank_frag_demo,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY frag_soc)   AS rank_frag_soc,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY frag_econ)  AS rank_frag_econ,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY frag_compl) AS rank_frag_compl
FROM base
