#!/usr/bin/env python3
"""
Report 20/80 finale - raggruppa per famiglia, dà raccomandazioni.
Legge catalog_scored.json e catalog_top60.json.
"""

import json, os
from collections import defaultdict

BASE = os.path.dirname(__file__)
SCORED = os.path.join(BASE, "catalog_scored.json")
TOP60 = os.path.join(BASE, "catalog_top60.json")

with open(SCORED) as f:
    scored_data = json.load(f)
with open(TOP60) as f:
    top60_data = json.load(f)

all_ds = scored_data["scored_datasets"]
top60 = top60_data["top60"]

# Costruisci dizionario da id → schema per top60
schema_map = {}
for ds in top60:
    if ds.get("schema"):
        schema_map[ds["id"]] = ds["schema"]

# ─── CLASSIFICAZIONE PER FAMIGLIA ───
FAMILIES = {
    "🚗 Varchi ZTL (traffico veicolare)": lambda x: x["id"].startswith("varco-n-"),
    "🚲 Mobilità dolce (bici, colonnine, parcheggi)": lambda x: any(k in x["id"] for k in ["bici", "conta-bici", "parcheggi", "sosta", "srm_sosta", "colonnine"]),
    "📡 WiFi / affollamento urbano": lambda x: any(k in x["id"] for k in ["wifi", "iperbole"]),
    "☁️ Ambiente e clima": lambda x: any(k in x["id"] for k in ["centraline", "aria", "temperatura", "precipitazioni", "qualita-aria"]),
    "👨‍👩‍👧‍👦 Dati demografici (popolazione, famiglie, emigrati)": lambda x: x["publisher"] and "Statistica" in x["publisher"],
    "🏛️ Trasparenza e amministrazione": lambda x: any(k in x["id"] for k in ["incarichi", "trasparenza", "atti-di-quartiere", "patti", "bilancio"]),
    "🏗️ Lavori pubblici e territorio": lambda x: any(k in x["id"] for k in ["lavori-pubblici", "carta-tecnica", "edifici", "popolazione-arborea", "alberi"]),
    "🛍️ Commercio e attività produttive": lambda x: any(k in x["id"] for k in ["commercio", "esercizi", "attivita-ricettive", "istanze"]),
    "🗺️ Dati geografici di base": lambda x: any(k in x["id"] for k in ["rifter_", "carta-tecnica", "aree-stradali", "arredo"]),
    "🎭 Cultura ed eventi": lambda x: any(k in x["id"] for k in ["eventi", "cultura", "agenda"]),
    "🗳️ Elezioni e referendum": lambda x: any(k in x["id"] for k in ["elezioni", "referendum", "voti"]),
    "🛞 Spire e flusso veicoli": lambda x: any(k in x["id"] for k in ["spire", "flusso-veicoli"]),
    "🏥 Welfare e sociale": lambda x: any(k in x["id"] for k in ["sportelli", "sociali", "sociale", "welfare", "centri-estivi"]),
    "📋 Altro": lambda x: True,
}

def classify(ds):
    for fam_name, rule in FAMILIES.items():
        if rule(ds):
            return fam_name
    return "📋 Altro"

# Raggruppa
families = defaultdict(list)
for ds in all_ds:
    fam = classify(ds)
    families[fam].append(ds)

# Per ogni famiglia, prendi i top 3
print("=" * 80)
print("📊 REPORT 20/80 — Catalogo OpenData Bologna")
print("   Classificazione per famiglia + top pick per famiglia")
print("   Basato su: records, frequenza, timeserie, geo, granularità colonne")
print("=" * 80)

freq_labels = {
    "DAILY": "giornaliero", "WEEKLY": "settimanale", "MONTHLY": "mensile",
    "QUARTERLY": "trimestrale", "ANNUAL": "annuale", "NEVER": "una tantum",
    "IRREGULAR": "irregolare", "OTHER": "continuo"
}

for fam_name in sorted(families.keys()):
    ds_list = sorted(families[fam_name], key=lambda x: -x["total_score"])
    n = len(ds_list)
    top = ds_list[:3]
    
    # Sommario famiglia
    total_records = sum(d["records_count"] for d in ds_list)
    min_score = min(d["total_score"] for d in ds_list)
    max_score = max(d["total_score"] for d in ds_list)
    
    print(f"\n{fam_name}  ({n} dataset, ~{total_records:,} records totali)")
    print(f"   Range score: {min_score:.1f} – {max_score:.1f}")
    
    for ds in top:
        id_short = ds["id"][:55]
        s = ds["scores"]
        features = [f for f in s if s[f] > 0 and f not in ("records_log", "theme_bonus", "keyword_granular")]
        feat_str = ", ".join(features).replace("timeserie", "📈").replace("geo", "🗺️")
        freq = freq_labels.get(ds["frequency"], ds["frequency"])
        
        # Granularità dallo schema se disponibile
        schema = schema_map.get(ds["id"])
        grain_str = ""
        if schema and schema.get("spatial_grain_hints"):
            grain_str = f"  granularità: {', '.join(schema['spatial_grain_hints'][:3])}"
        
        cols_info = ""
        if schema:
            cols_info = f"  [{schema['total_cols']} col, {schema['num_cols']} num]"
        
        print(f"   ⭐ {ds['total_score']:5.1f}  {id_short}")
        print(f"      rec={ds['records_count']:>8d}  freq={freq:12s}{cols_info}{grain_str}")

print(f"\n{'='*80}")
print("🎯 RACCOMANDAZIONI — I dataset con miglior rapporto valore/sforzo")
print("   (che non siano solo un varco ZTL tra 40 identici)")
print(f"{'='*80}")

# Raccomandazioni "curate": dataset che si distinguono per unicità + qualità
recommendations = [
    # (dataset_id, perché, uso potenziale)
    
    # MOBILITÀ (aggregato)
    ("varchi-ztl (40+ dataset)", 
     "40+ varchi con 19 colonne ciascuno (13 numeriche). Passaggi veicolari classificati per tipologia (auto, bus, moto, lista bianca/nera). Geolocalizzati. 250k records/mese a varco. Agg. mensile.",
     "Costruire serie storica del traffico a Bologna per varco, confronto pre/post ZTL, classificazione veicoli."),
    
    ("colonnine-conta-bici", 
     "516k records. Conta biciclette. Monthly. Ha timeserie + geo.",
     "Trend mobilità ciclabile, stagionalità, impatto infrastrutture."),
    
    ("srm_sosta", 
     "Transazioni parcometri vs app mobile. Mensile. Poco records (87) ma indicatore economico.",
     "Evoluzione sosta: parcometro vs mobile, trend pagamento digitale."),
    
    ("parcheggi_dati_trento_trieste", 
     "1.5M records, disponibilità parcheggi DAILY. Il dataset più grande del catalogo.",
     "Disponibilità parcheggi in tempo reale e serie storica. Incrocio con ZTL e eventi."),
    
    # DEMOGRAFIA
    ("annuale_popolazione_residente_eta_quart_zonadal1986", 
     "239k records. Popolazione per età, sesso, cittadinanza, quartiere, zona. Serie dal 1986! Annuale.",
     "Serie storica demografica più lunga del portale. Analisi invecchiamento, migrazioni per quartiere."),
    
    ("emigrati-secondo-la-destinazione-per-sesso-quartiere-e-zona-di-provenienza-serie", 
     "81k records. Emigrati per destinazione, sesso, quartiere. Serie dal 1986.",
     "Flussi migratori per quartiere. Incrocio con dati lavoro/istruzione."),
    
    ("popolazione-residente-straniera-per-cittadinanzasesso-quartiere-e-zona-serie-st0", 
     "81k records. Stranieri per cittadinanza, quartiere. Serie storica.",
     "Distribuzione cittadinanze per quartiere. Integrazione e cambiamento urbano."),
    
    ("famiglie-residenti-per-eta-tipologia-e-cittadinanza-del-capofamiglia-per-quartie", 
     "78k records. Famiglie per tipologia, età capofamiglia, quartiere.",
     "Struttura familiare nei quartieri. Nuclei monogenitoriali, anziani soli."),
    
    ("popolazione-residente-in-istituti-di-convivenza-per-cittadinanza-eta-dimensione-", 
     "92k records. Convivenze (residenze, RSA, caserme) per tipo, quartiere.",
     "Popolazione fragile per quartiere. Residenze sanitarie, studentati, caserme."),
    
    # AMBIENTE
    ("centraline-qualita-aria + dati-centraline-bologna-storico", 
     "696k + 43k records. Qualità aria da centraline fisse. Storico + daily.",
     "Serie storica inquinamento atmosferico. Incrocio con traffico ZTL e meteo."),
    
    ("temperature_bologna + precipitazioni_bologna", 
     "9k records ciascuno. Daily. Dati meteo Bologna.",
     "Serie meteo. Incrocio con qualità aria, traffico, eventi."),
    
    # TRASPARENZA
    ("incarichi-di-collaborazione", 
     "747 records. Incarichi consulenze e collaborazioni. Update WEEKLY. Dal 2012.",
     "Dataset di trasparenza più aggiornato del portale. Incrocio con ANAC."),
    
    ("atti-di-quartiere", 
     "3.9k records. Atti deliberativi dei quartieri. Trimestrale.",
     "Attività amministrativa per quartiere. Confronto con dati anagrafici e partecipazione."),
    
    ("patti-di-collaborazione", 
     "957 records. Patti di collaborazione cittadini/comune. Weekly. Geolocalizzati.",
     "Beni comuni e partecipazione civica. Mappatura progettualità diffusa."),
    
    # COMMERCIO
    ("elenco-esercizi-commercio-in-sede-fissa", 
     "33k records. Esercizi commerciali geolocalizzati. Annuale.",
     "Mappa commerciale di Bologna. Incrocio con dati demografici per quartiere."),
    
    ("elenco-esercizi-somministrazioni", 
     "18k records. Bar, ristoranti, pubblici esercizi. Geolocalizzati. Annuale.",
     "Vita notturna e ristorazione per zona."),
    
    # EVENTI
    ("eventi-bologna-agenda-cultura", 
     "30k records. Eventi culturali geolocalizzati. Daily. 18 colonne.",
     "Agenda culturale della città. Incrocio con WiFi affollamento, trasporti."),
    
    # RILEVAZIONI
    ("rilevazione-flusso-veicoli-tramite-spire", 
     "300k records/anno. Spire di rilevamento traffico. Annuale (NEVER=storico).",
     "Mappa flussi veicolari. Complementare ai varchi ZTL (spire fuori ZTL)."),
    
    ("segnalazioni-open-citizen-relationship-management-czrm", 
     "123k records. Segnalazioni cittadini. Mensile. Geolocalizzate.",
     "Manutenzione urbana partecipata. Cittadinanza attiva per quartiere."),
]

for i, (name, why, use) in enumerate(recommendations, 1):
    print(f"\n#{i:2d} {name}")
    print(f"    💎 {why}")
    print(f"    🔬 {use}")

print(f"\n{'='*80}")
print("📁 File generati:")
print(f"   _local/explore/bologna/catalog_full.json       — catalogo completo (702 ds)")
print(f"   _local/explore/bologna/catalog_scored.json     — con punteggio per ogni ds")
print(f"   _local/explore/bologna/catalog_top60.json      — top60 con schema colonne")
print(f"   _local/explore/bologna/query_catalog.py        — per fare query sul catalogo")
