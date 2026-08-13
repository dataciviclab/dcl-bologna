-- mart_esercizi_stato.sql: esercizi per stato (Attivo/Cessato/Sospeso/Diniegato)
--
-- Il quadro complessivo del tessuto commerciale: quanti sono attivi oggi,
-- quanti sono cessati nello storico (dal 1976).

SELECT
    stato,
    count(*) AS n_esercizi,
    count(*) FILTER (WHERE data_cessazione_attivita IS NOT NULL) AS con_data_cessazione
FROM clean_input
GROUP BY stato
ORDER BY n_esercizi DESC
