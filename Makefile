# Bologna Pilota — Makefile
# ==========================
# make status     → mostra stato di tutti i dataset
# make registry   → rigenera registry.json
# make fetch      → scarica tutti i dataset non presenti
# make fetch-all  → riscarica tutto (--force)
# make fetch/<id> → scarica un dataset specifico
# make varchi     → fetch dedicato: 80 varchi ZTL + merge in un parquet
# make check      → validazione + registry + status
# make add/<id>   → configura un nuovo dataset dal catalogo

PYTHON = python3
PIPELINE = pipeline

.PHONY: status registry fetch fetch-all check

# --- Stato ---
status:
	@$(PYTHON) $(PIPELINE)/check.py --status

registry:
	@$(PYTHON) $(PIPELINE)/check.py --registry

# --- Fetch ---
fetch:
	@echo "=== Fetch: scarica dataset mancanti ==="
	@$(PYTHON) $(PIPELINE)/fetch.py
	@$(MAKE) registry

fetch-all:
	@echo "=== Fetch: riscarica tutto ==="
	@$(PYTHON) $(PIPELINE)/fetch.py --force
	@$(MAKE) registry

fetch/%:
	@echo "=== Fetch: $* ==="
	@$(PYTHON) $(PIPELINE)/fetch.py $* $(if $(filter --force,$(ARGS)),--force)
	@$(MAKE) registry

# --- Varchi ZTL: fetch dedicato (80 varco-n-* dal catalogo + merge) ---
varchi:
	@echo "=== Varchi ZTL: fetch 80 varchi + merge ==="
	@$(PYTHON) $(PIPELINE)/fetch_varchi.py
	@$(PYTHON) $(PIPELINE)/fetch_varchi.py --merge
	@$(MAKE) registry

varchi-quick:
	@echo "=== Varchi ZTL: quick (5 varchi di test) ==="
	@$(PYTHON) $(PIPELINE)/fetch_varchi.py --quick
	@$(PYTHON) $(PIPELINE)/fetch_varchi.py --merge
	@$(MAKE) registry

# --- Check completo ---
check: registry status

# --- Utility ---
list:
	@$(PYTHON) $(PIPELINE)/fetch.py --list

info/%:
	@$(PYTHON) $(PIPELINE)/fetch.py --info $*

# --- Query ---
query:
	@echo "Uso: make q/<dataset> CMD='SELECT ... FROM data'"
	@echo "Oppure: python3 pipeline/query.py <dataset> '<sql>'"

q/%:
	@$(PYTHON) $(PIPELINE)/query.py $* "$(CMD)"

# --- Clean ---
clean:
	@echo "Rimuovi _data/*.parquet?"
	@rm -i _data/*.parquet

# --- Help ---
help:
	@echo "Bologna Pilota — Makefile"
	@echo ""
	@echo "make status           Stato dei dataset"
	@echo "make registry         Rigenera registry.json"
	@echo "make fetch            Scarica dataset mancanti"
	@echo "make fetch-all        Riscarica tutto"
	@echo "make fetch/popolazione-quartiere  Scarica specifico"
	@echo "make varchi           Fetch dedicato: 80 varchi ZTL + merge"
	@echo "make check            Validazione completa"
	@echo "make list             Elenca dataset configurati"
	@echo "make info/popolazione-quartiere   Info su dataset"
	@echo "make q/popolazione-quartiere CMD='SELECT ...'  Query SQL"
	@echo "make clean            Rimuovi dati scaricati"
