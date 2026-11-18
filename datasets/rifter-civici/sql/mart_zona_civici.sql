-- mart_zona_civici.sql: consistenza della toponomastica per quartiere e zona
--
-- Serve a due cose: capire quante vie ha ogni zona (denominatore per i tassi)
-- e verificare che il crosswalk copra tutte le zone attese.

SELECT
    quartiere,
    zona,
    COUNT(*)                    AS civici,
    COUNT(DISTINCT codvia)      AS vie,
    COUNT(DISTINCT area_statistica) AS aree_statistiche,
    MIN(lat)                    AS lat_min,
    MAX(lat)                    AS lat_max
FROM clean_input
GROUP BY quartiere, zona
