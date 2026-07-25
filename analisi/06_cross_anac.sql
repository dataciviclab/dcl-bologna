-- ============================================================
-- Analisi 06: Cross Incarichi Bologna ↔ ANAC
-- Dataset: incarichi (Bologna), anac_aggiudicatari (Lab)
-- ============================================================

-- 1. Partite IVA negli incarichi Bologna (top 20 per importo)
SELECT partita_iva, ragione_sociale, round(sum(importo_euro), 0) as totale_incarichi
FROM read_parquet('_data/incarichi.parquet')
WHERE partita_iva IS NOT NULL AND partita_iva != '' AND importo_euro > 0
GROUP BY partita_iva, ragione_sociale
ORDER BY totale_incarichi DESC
LIMIT 20;

-- 2. Cross: cerca le stesse partite IVA in ANAC
--    (esegui su clean-query, sostituisci le partite IVA)
-- SELECT codice_fiscale, count(*) as gare_anac
-- FROM anac_aggiudicatari
-- WHERE codice_fiscale IN ('piva1', 'piva2', ...)
-- GROUP BY codice_fiscale
-- ORDER BY gare_anac DESC;

-- 3. Risultato noto: ACG Auditing ha 390 gare ANAC + 298k€ incarichi BO
