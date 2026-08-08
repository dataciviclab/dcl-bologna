# Come lavorare su dcl-bologna

## La tua prima PR

Benvenuto! Se sei nuovo, il percorso più semplice:

1. **Trova una issue con label `good first issue`** — sono pensate per chi inizia: toccano pochi file e hanno istruzioni nel body.
2. **Apri una issue o una discussion prima di lavorare** se hai un'idea tua — evitiamo lavoro duplicato.
3. **Crea un branch** con nome descrittivo: `feat/<cosa>`, `fix/<cosa>`, `docs/<cosa>`, `chore/<cosa>`.
4. **Fai la modifica**, poi verifica in locale (vedi sotto).
5. **Apri la PR** — il template guida la descrizione e la checklist. La CI (`.github/workflows/ci.yml`) gira i preflight automaticamente.

Verifica in locale prima della PR:

```bash
# toolkit dal venv del Lab (o pip install git+https://github.com/dataciviclab/toolkit.git)
toolkit run preflight --config datasets/<slug>/dataset.yml   # config valido
toolkit run --config datasets/<slug>/dataset.yml             # status: passed
```

## Aggiungere un nuovo dataset

I dataset vivono in `datasets/<slug>/` con lo **standard candidate del Lab**
(raw → clean → mart via [toolkit](https://github.com/dataciviclab/toolkit)). Riferimento:
[docs/candidate-standard.md](https://github.com/dataciviclab/dataset-incubator/blob/main/docs/candidate-standard.md).

```bash
# 1. Crea datasets/<slug>/ con:
#    - dataset.yml      → nome, years, source_id, tags, category, raw/clean/mart
#    - sql/clean.sql    → SELECT ... FROM raw_input (typing, {year}, macro standard)
#    - sql/mart_*.sql   → aggregazioni (SELECT ... FROM clean_input)
#    - README.md + notes.md

# 2. Esegui la pipeline
toolkit run --config datasets/<slug>/dataset.yml
#    target: status: passed, readiness: ready (8/8)

# 3. Verifica schema e dati
toolkit inspect config --config datasets/<slug>/dataset.yml

# 4. Aggiorna README.md (tabella dataset)
```

Per le convenzioni del toolkit (source types, macro, placeholder `{year}`, mart multi-anno):
`toolkit contract --layer all` prima di scrivere.

## Fare un'analisi

```bash
# 1. Crea analisi/XX_nome.sql con:
#    - header con descrizione e dataset necessari
#    - query 0: verifica copertura (date, records)
#    - query 1..N: analisi
#    - ogni query deve funzionare in DuckDB direttamente

# 2. Esegui l'analisi sui parquet clean (out/data/clean/<slug>/<anno>/)
python3 -c "
import duckdb
con = duckdb.connect()
con.execute('SELECT * FROM read_parquet(\"out/data/clean/ds/2026/ds_2026_clean.parquet\") a
             JOIN read_parquet(\"out/data/clean/ds2/2026/ds2_2026_clean.parquet\") b ON a.data = b.data
             LIMIT 10').fetchdf()
"

# 3. Se emergono numeri interessanti, aggiorna README o Discussion
```

## Commit e push

```bash
git add -A
git commit -m "tipo: messaggio"

# tipi: feat (nuovo dataset/analisi), fix (correzione),
#       docs (README, discussioni), chore (manutenzione)
```

Prima di pushare:
- `toolkit run preflight --config datasets/<slug>/dataset.yml` passa (la CI lo rifà)
- Controlla che `out/`, `datasets/*/cache/` e i parquet candidate non siano in git (`git status`)
- Il commit deve essere stabile: chi clona deve poter fare `toolkit run` e vedere tutto funzionare

## CI

Il repo ha due workflow GitHub Actions:

- **`ci.yml`** (su ogni PR/push): valida i config dataset con `toolkit run preflight`. `varchi-ztl` è escluso dal preflight — usa un mergiato generato dallo script di bootstrap, gestito dal workflow pipeline.
- **`pipeline.yml`** (post-merge + schedule mensile + manuale): esegue il run dei dataset, il bootstrap di `varchi-ztl` (con cache persistente), e la sync GCS **graceful** (skippata se le chiavi non sono configurate).

## Principi

- **I dati in `out/` e nelle cache (`datasets/*/cache/`) non vanno in git.** Sono rigenerabili con il toolkit. Il repo contiene solo codice e configurazioni.
- **Un dataset = una cartella `datasets/<slug>/`.** Config + SQL di pulizia + mart. Niente pipeline custom.
- **Le analisi in SQL**, non in Python. Python solo per orchestrazione (script di bootstrap, es. varchi) e visualizzazione. L'analisi deve essere riproducibile.
- **Se un dato non è verificabile, non esiste.** Ogni numero nel README deve avere una query alle spalle.
- **Prima di aggiungere un dataset, controlla se si incrocia con uno già presente.** Se no, probabilmente non serve.
