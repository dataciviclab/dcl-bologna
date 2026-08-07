# dcl-bologna — Makefile
# ==========================
# Tutti i dataset vivono in datasets/<slug>/ e sono gestiti dal toolkit.
# https://github.com/dataciviclab/toolkit
#
# make run/<slug>            → esegue la pipeline completa (raw→clean→mart)
# make status/<slug>         → stato + readiness di un dataset
# make fetch/<slug>          → scarica/aggiorna i dati raw
# make clean/<slug>          → pulisce l'output di un dataset
# make varchi-bootstrap      → bootstrap varchi-ztl (merge 80 dataset, ~2 min)
# make help                  → questo aiuto

TOOLKIT = toolkit
CONFIG = datasets

.PHONY: help

# --- Pipeline toolkit ---
run/%:
	@$(TOOLKIT) run --config $(CONFIG)/$*/dataset.yml

status/%:
	@$(TOOLKIT) inspect config --config $(CONFIG)/$*/dataset.yml

fetch/%:
	@$(TOOLKIT) run raw --config $(CONFIG)/$*/dataset.yml

clean/%:
	@rm -rf out/data/raw/$* out/data/clean/$* out/data/mart/$*

# --- Varchi ZTL: bootstrap (merge 80 dataset, una tantum) ---
varchi-bootstrap:
	@echo "=== Varchi ZTL: merge 80 varchi (bootstrap) ==="
	@cd datasets/varchi-ztl && python3 fetch_varchi_toolkit.py --fetch

# --- Help ---
help:
	@echo "dcl-bologna — Makefile (toolkit)"
	@echo ""
	@echo "make run/popolazione-quartiere    Esegue la pipeline completa"
	@echo "make status/popolazione-quartiere Stato + readiness"
	@echo "make fetch/popolazione-quartiere  Aggiorna i dati raw"
	@echo "make clean/popolazione-quartiere  Rimuove l'output del dataset"
	@echo "make varchi-bootstrap             Merge 80 varchi (una tantum)"
