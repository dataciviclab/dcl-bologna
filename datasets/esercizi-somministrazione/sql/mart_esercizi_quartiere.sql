-- mart_esercizi_quartiere.sql: esercizi per quartiere × stato
--
-- Il tessuto commerciale per quartiere: attivi vs cessati.
-- La base per la lettura "desertificazione commerciale".
--
-- NOTA (review PR #45): il clean contiene sia i 6 quartieri attuali sia
-- valori soppressi nel 2016 (Borgo Panigale, Porto, Reno, San Donato,
-- San Vitale, Saragozza) + NULL. Il flag `quartiere_attuale` separa i
-- territori correnti dai residui storici: chi consuma il mart filtra
-- `quartiere_attuale = TRUE` senza hardcodare i nomi (l'analisi 12 usa
-- questo flag, non un NOT IN).

SELECT
    quartiere,
    stato,
    count(*) AS n_esercizi,
    count(*) FILTER (WHERE bottega_storica IS NOT NULL AND bottega_storica <> '') AS n_botteghe_storiche,
    quartiere IN ('Borgo Panigale - Reno', 'Navile', 'Porto - Saragozza',
                  'San Donato - San Vitale', 'Santo Stefano', 'Savena') AS quartiere_attuale
FROM clean_input
WHERE quartiere IS NOT NULL AND quartiere <> ''
GROUP BY quartiere, stato
ORDER BY quartiere, stato
