-- mart_famiglie_quartiere.sql: famiglie per quartiere × anno
--
-- Totale famiglie e quota per quartiere e anno. Confrontabile con
-- popolazione (indice: persone per famiglia) via join a runtime.

SELECT
    anno,
    quartiere,
    SUM(numero_famiglie) AS totale_famiglie,
    ROUND(SUM(numero_famiglie) * 100.0 / NULLIF(SUM(SUM(numero_famiglie)) OVER (PARTITION BY anno), 0), 1) AS quota_pct,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY SUM(numero_famiglie)) AS rank_quartiere
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY anno, quartiere
