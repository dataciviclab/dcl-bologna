-- mart_esercizi_quartiere.sql: esercizi per quartiere × stato
--
-- Il tessuto commerciale per quartiere: attivi vs cessati.
-- La base per la lettura "desertificazione commerciale".

SELECT
    quartiere,
    stato,
    count(*) AS n_esercizi,
    count(*) FILTER (WHERE bottega_storica IS NOT NULL AND bottega_storica <> '') AS n_botteghe_storiche
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY quartiere, stato
ORDER BY quartiere, stato
