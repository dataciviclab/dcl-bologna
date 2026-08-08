## Cosa cambia

_Descrivi in una frase cosa fa questa PR e perché. Se chiude un'issue, linkala: `Closes #123`._

## Tipo di change

- [ ] 📥 Nuovo dataset (`datasets/<slug>/`)
- [ ] 📄 Nuova analisi (`analisi/*.sql`)
- [ ] 🐛 Bugfix (clean.sql, mart, mapping, config)
- [ ] 🔧 Infrastruttura (CI, template, docs)

## Checklist

- [ ] `toolkit run preflight --config datasets/<slug>/dataset.yml` passa
- [ ] `toolkit run --config datasets/<slug>/dataset.yml` → `status: passed`, `readiness: ready`
- [ ] README aggiornato se cambiano dataset attivi o roadmap
- [ ] Nessuna modifica a file non correlati

## Note per il review

_Qualcosa che il reviewer deve sapere? Verifiche eseguite? Dati da cui partire?_
