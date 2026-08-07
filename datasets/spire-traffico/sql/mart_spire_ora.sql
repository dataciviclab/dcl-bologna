-- mart_spire_ora.sql: profilo orario del traffico per via × anno
--
-- Passaggi medi per fascia oraria, per via e anno. Utile per confrontare
-- i picchi di traffico tra vie e per incrociare bici (conta-bici) vs auto.

SELECT
    anno,
    nome_via,
    ora_inizio,
    fascia_oraria,
    ROUND(AVG(passaggi), 1) AS passaggi_medi,
    MAX(passaggi)           AS passaggi_max
FROM clean_input
GROUP BY anno, nome_via, ora_inizio, fascia_oraria
