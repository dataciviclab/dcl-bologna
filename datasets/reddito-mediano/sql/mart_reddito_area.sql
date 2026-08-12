-- mart_reddito_area.sql: reddito mediano per area statistica × anno
--
-- Il reddito imponibile mediano per area + contribuenti, con rank
-- nel comune per anno. Base del blocco "economia per area" (join
-- 1:1 con indici-fragilita e esercizi-somministrazioni).

SELECT
    anno,
    area_statistica,
    reddito_imponibile_mediano,
    numero_contribuenti,
    PERCENT_RANK() OVER (PARTITION BY anno ORDER BY reddito_imponibile_mediano) AS rank_reddito
FROM clean_input
ORDER BY anno, rank_reddito DESC
