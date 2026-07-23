#!/usr/bin/env python3
"""
Scoring 20/80 del catalogo Bologna.
Step 1: score basato su metadati (records, features, freq, recency, temi)
Step 2: fetch schema colonne per top 60 via API → valuta granularità reale
Step 3: ranking finale composito
"""

import json, os, sys, time, re
from datetime import datetime, timezone
from collections import defaultdict
from urllib.request import urlopen, Request
from urllib.error import HTTPError

CATALOG = os.path.join(os.path.dirname(__file__), "catalog_full.json")
OUT_SCORED = os.path.join(os.path.dirname(__file__), "catalog_scored.json")
OUT_TOP = os.path.join(os.path.dirname(__file__), "catalog_top60.json")
API_BASE = "https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets"

# Pesi per scoring
WEIGHTS = {
    "records_log":      2.0,   # volume dati (log scale)
    "timeserie":        2.5,   # serie storica = valore longitudinale
    "geo":              2.5,   # dato geolocalizzato = analisi spaziale
    "frequency":        2.0,   # update frequente = dato vivo
    "recency":          1.5,   # recente = attivo
    "theme_bonus":      1.0,   # temi preferiti (mobility, demography, env)
    "keyword_granular": 1.5,   # quartiere/zona/sezione nel titolo
}

# Mappa frequenze → punteggio
FREQ_SCORE = {
    "DAILY": 5.0,
    "WEEKLY": 4.5,
    "MONTHLY": 3.5,
    "QUARTERLY": 2.5,
    "ANNUAL": 2.0,
    "IRREGULAR": 0.5,
    "NEVER": 0.0,
    "BIENNIAL": 1.0,
    "OTHER": 0.5,
}

# Temi con bonus
THEME_BONUS = {
    "Trasporti": 2.0,
    "Popolazione e società": 1.5,
    "Ambiente": 2.0,
    "Governo e settore pubblico": 0.5,
    "Scienza e tecnologia": 1.0,
    "Economia e finanze": 0.5,
}

# Parole chiave di granularità fine (nel titolo)
GRANULAR_KEYWORDS = [
    "quartiere", "zona", "sezione", "varco", "via ", "strada", "civico",
    "indirizzo", "coordinate", "spire", "parcheggio", "centralina",
    "area statistica", "capoluogo",
]

def load_catalog():
    with open(CATALOG) as f:
        return json.load(f)

def freq_label(uri):
    if not uri:
        return "UNKNOWN"
    return uri.split("/")[-1]

def score_frequency(freq_uri):
    label = freq_label(freq_uri)
    return FREQ_SCORE.get(label, 0.0)

def score_recency(modified_str):
    """Quanto è recente l'ultima modifica (0-5)."""
    if not modified_str:
        return 0.0
    try:
        mod = datetime.fromisoformat(modified_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        days = (now - mod).days
        if days <= 1: return 5.0
        if days <= 7: return 4.5
        if days <= 30: return 4.0
        if days <= 90: return 3.0
        if days <= 365: return 2.0
        if days <= 730: return 1.0
        return 0.0
    except:
        return 0.0

def score_records_log(n):
    if n <= 0: return 0.0
    import math
    # log10 da 1 a 7+ (1 record → ~0, 1M → ~6)
    return min(math.log10(n + 1) / 1.5, 5.0)

def has_granular_keywords(title, description, keywords):
    text = f"{title} {description} {' '.join(keywords or [])}".lower()
    count = sum(1 for kw in GRANULAR_KEYWORDS if kw in text)
    return min(count * 0.5, 3.0)  # max 3 punti

def compute_scores(data):
    datasets = data["datasets"]
    results = []
    
    for ds in datasets:
        title = ds.get("title", "")
        desc = ds.get("description", "")
        keywords = ds.get("keyword") or []
        features = ds.get("features", [])
        theme = ds.get("theme", [])
        
        scores = {}
        scores["records_log"] = score_records_log(ds.get("records_count", 0))
        scores["timeserie"] = 5.0 if "timeserie" in features else 0.0
        scores["geo"] = 5.0 if "geo" in features else 0.0
        scores["frequency"] = score_frequency(ds.get("accrualperiodicity", ""))
        scores["recency"] = score_recency(ds.get("modified", ""))
        scores["theme_bonus"] = max(THEME_BONUS.get(t, 0.0) for t in theme) if theme else 0.0
        scores["keyword_granular"] = has_granular_keywords(title, desc, keywords)
        
        total = sum(scores[k] * WEIGHTS[k] for k in scores)
        
        results.append({
            "id": ds["id"],
            "title": title,
            "theme": theme,
            "records_count": ds["records_count"],
            "features": features,
            "frequency": freq_label(ds.get("accrualperiodicity", "")),
            "modified": ds.get("modified", ""),
            "license": ds.get("license", ""),
            "publisher": ds.get("publisher", ""),
            "scores": scores,
            "total_score": round(total, 2),
        })
    
    results.sort(key=lambda x: -x["total_score"])
    return results

def pp_score(d, rank=None):
    prefix = f"#{rank:3d} " if rank else ""
    s = d["scores"]
    features_str = ", ".join(d["features"]) if d["features"] else "—"
    print(f"{prefix}{d['id']:55s} score={d['total_score']:6.2f}  rec={d['records_count']:>8d}  "
          f"freq={d['frequency']:10s}  [{features_str}]")

# ─── STEP 2: Fetch schema colonne via API ───

def fetch_schema(dataset_id):
    """Recupera lo schema (campi) di un dataset via API."""
    url = f"{API_BASE}/{dataset_id}"
    req = Request(url, headers={"Accept": "application/json"})
    try:
        with urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
    except (HTTPError, Exception) as e:
        return None, str(e)
    
    ds = data.get("dataset", data)  # a volte è annidato
    fields = ds.get("fields", [])
    if not fields:
        # proviamo a vedere se la struttura è diversa
        fields = data.get("fields", [])
    if not fields:
        # proviamo con dataset[0]
        results = data.get("results", [])
        if results:
            fields = results[0].get("fields", [])
    
    schema = []
    for f in fields:
        schema.append({
            "name": f.get("name", ""),
            "type": f.get("type", ""),
            "label": f.get("label", ""),
            "annotations": f.get("annotations", {}),
        })
    
    # Valutazione granularità dalle colonne
    col_names = [f["name"].lower() for f in schema]
    col_types = [f["type"] for f in schema]
    num_cols = sum(1 for t in col_types if t in ("int", "double", "long"))
    text_cols = sum(1 for t in col_types if t in ("text", "string"))
    date_cols = sum(1 for t in col_types if t in ("date", "datetime"))
    geo_cols = sum(1 for t in col_types if t in ("geo_point_2d", "geo_shape"))
    
    # Dimensione della granularità spaziale
    spatial_grain = 0
    grain_hints = []
    for c in col_names:
        if "quartiere" in c: spatial_grain += 3; grain_hints.append("quartiere")
        if "zona" in c and "quartiere" not in c: spatial_grain += 2; grain_hints.append("zona")
        if "sezione" in c: spatial_grain += 2; grain_hints.append("sezione")
        if "via" in c or "indirizzo" in c or "civico" in c: spatial_grain += 4; grain_hints.append("indirizzo")
        if "varco" in c: spatial_grain += 4; grain_hints.append("varco")
        if "coordinate" in c or "geopoint" in c: spatial_grain += 3; grain_hints.append("coordinate")
    
    return {
        "total_cols": len(schema),
        "num_cols": num_cols,
        "text_cols": text_cols,
        "date_cols": date_cols,
        "geo_cols": geo_cols,
        "spatial_grain_score": min(spatial_grain, 10),
        "spatial_grain_hints": list(set(grain_hints)),
        "columns": [f["name"] for f in schema],
        "col_types": {f["name"]: f["type"] for f in schema},
    }, None


def main():
    print("=" * 70)
    print("📊 SCORING 20/80 — Catalogo OpenData Bologna")
    print("=" * 70)
    
    data = load_catalog()
    scored = compute_scores(data)
    
    n = len(scored)
    top20pct = int(n * 0.2)
    
    print(f"\n🏆 TOP {top20pct} (20% del catalogo)")
    print("-" * 120)
    for i, ds in enumerate(scored[:top20pct]):
        pp_score(ds, i+1)
    
    print(f"\n📉 CODA (ultimi 10)")
    for ds in scored[-10:]:
        pp_score(ds)
    
    # Statistiche distribuzione score
    scores = [ds["total_score"] for ds in scored]
    print(f"\n📊 Distribuzione score:")
    print(f"   Media: {sum(scores)/len(scores):.1f}")
    print(f"   Mediana: {sorted(scores)[len(scores)//2]:.1f}")
    print(f"   Max: {max(scores):.1f}")
    print(f"   Min: {min(scores):.1f}")
    
    # Salva scored completo
    with open(OUT_SCORED, "w") as f:
        json.dump({
            "total": n,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "scored_datasets": scored
        }, f, indent=2, ensure_ascii=False)
    print(f"\n💾 Salvato scoring completo in {OUT_SCORED}")
    
    # ─── STEP 2: Fetch schema per top 60 ───
    print(f"\n{'='*70}")
    print(f"🔍 STEP 2 — Fetch schema colonne per top 60")
    print(f"{'='*70}")
    
    top60 = scored[:60]
    enriched = []
    
    for i, ds in enumerate(top60):
        print(f"   [{i+1}/60] {ds['id']}... ", end="", flush=True)
        schema, err = fetch_schema(ds["id"])
        if schema:
            grains = ", ".join(schema["spatial_grain_hints"]) or "—"
            print(f"ok ({schema['total_cols']} cols, {schema['num_cols']} num, grain: {grains})")
            ds["schema"] = schema
            
            # Aggiorna score con granularità
            ds["scores"]["spatial_grain"] = schema["spatial_grain_score"]
            # Num colonne numeriche come proxy di ricchezza
            ds["scores"]["numeric_richness"] = min(schema["num_cols"] * 0.5, 3.0)
            
            # Ricalcola totale
            WEIGHTS2 = {**WEIGHTS, "spatial_grain": 2.0, "numeric_richness": 1.0}
            total2 = sum(ds["scores"].get(k, 0) * WEIGHTS2.get(k, 1.0) 
                        for k in set(list(ds["scores"].keys()) + ["spatial_grain", "numeric_richness"]))
            ds["total_score_v2"] = round(total2, 2)
            enriched.append(ds)
        else:
            print(f"ERRORE: {err}")
            ds["schema"] = None
            ds["total_score_v2"] = ds["total_score"]
            enriched.append(ds)
        
        time.sleep(0.2)
    
    # Ri-ordina per score v2
    enriched.sort(key=lambda x: -x.get("total_score_v2", x["total_score"]))
    
    # Salva top 60
    with open(OUT_TOP, "w") as f:
        json.dump({
            "total": n,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "top60": enriched
        }, f, indent=2, ensure_ascii=False)
    print(f"\n💾 Salvato top60 in {OUT_TOP}")
    
    # Report finale
    print(f"\n{'='*70}")
    print(f"📋 REPORT FINALE — Top 30 (score composito v2)")
    print(f"{'='*70}")
    
    for i, ds in enumerate(enriched[:30]):
        s = ds["scores"]
        schema = ds.get("schema")
        
        id_short = ds["id"][:50]
        features_str = ", ".join(ds["features"])[:25]
        score = ds.get("total_score_v2", ds["total_score"])
        
        grain_info = ""
        if schema:
            hints = schema.get("spatial_grain_hints", [])
            grain_info = f" grain:{','.join(hints)}" if hints else ""
        
        print(f"\n#{i+1:2d}  {id_short}")
        print(f"     Score: {score:5.1f}  Records: {ds['records_count']:>8d}  Freq: {ds['frequency']:10s}  [{features_str}]{grain_info}")
        print(f"     Tema: {', '.join(ds['theme'])[:70]}")
        if schema:
            print(f"     Colonne: {schema['total_cols']} totali, {schema['num_cols']} numeriche, {schema['date_cols']} date, {schema['geo_cols']} geo")
            if i < 5:
                cols_preview = schema["columns"][:10]
                print(f"     Col: {', '.join(cols_preview)}")

if __name__ == "__main__":
    main()
