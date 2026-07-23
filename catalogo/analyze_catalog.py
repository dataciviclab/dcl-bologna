#!/usr/bin/env python3
"""Analisi e consultazione del catalogo Bologna."""

import json, os, sys
from collections import Counter, defaultdict
from datetime import datetime

CATALOG = os.path.join(os.path.dirname(__file__), "catalog_full.json")

with open(CATALOG) as f:
    data = json.load(f)

datasets = data["datasets"]
total = len(datasets)
print(f"📊 Catalogo OpenData Comune di Bologna")
print(f"   Dataset: {total}")
print(f"   Generato: {data['generated_at']}")
print()

# --- 1. TEMI ---
themes = Counter()
for ds in datasets:
    for t in ds.get("theme", []):
        themes[t] += 1

print("🏷️  THEMES (distribuzione)")
for t, n in themes.most_common():
    print(f"   {t:35s} {n:4d}")
print()

# --- 2. LICENZE ---
licenses = Counter()
for ds in datasets:
    l = ds.get("license", "N/A")
    licenses[l] += 1

print("📜 LICENZE")
for l, n in licenses.most_common():
    print(f"   {l:45s} {n:4d}")
print()

# --- 3. PUBLISHER ---
publishers = Counter()
for ds in datasets:
    p = ds.get("publisher") or "(non specificato)"
    publishers[p] += 1

print("🏢 PUBLISHER (top 15)")
for p, n in publishers.most_common(15):
    print(f"   {p:40s} {n:4d}")
print()

# --- 4. FREQUENZA AGGIORNAMENTO ---
freqs = Counter()
freq_labels = {
    "http://publications.europa.eu/resource/authority/frequency/NEVER": "NEVER",
    "http://publications.europa.eu/resource/authority/frequency/ANNUAL": "ANNUAL",
    "http://publications.europa.eu/resource/authority/frequency/IRREG": "IRREGULAR",
    "http://publications.europa.eu/resource/authority/frequency/MONTHLY": "MONTHLY",
    "http://publications.europa.eu/resource/authority/frequency/WEEKLY": "WEEKLY",
    "http://publications.europa.eu/resource/authority/frequency/DAILY": "DAILY",
    "http://publications.europa.eu/resource/authority/frequency/QUARTERLY": "QUARTERLY",
    "http://publications.europa.eu/resource/authority/frequency/CONT": "CONTINUOUS",
    "http://publications.europa.eu/resource/authority/frequency/BIENNIAL": "BIENNIAL",
}
for ds in datasets:
    f = ds.get("accrualperiodicity", "")
    label = freq_labels.get(f, f.split("/")[-1] if f else "UNKNOWN")
    freqs[label] += 1

print("🔄 FREQUENZA AGGIORNAMENTO")
for f, n in freqs.most_common():
    print(f"   {f:15s} {n:4d}")
print()

# --- 5. RECORDS (conteggio) ---
def records_bin(n):
    if n == 0: return "0"
    if n <= 10: return "1-10"
    if n <= 100: return "11-100"
    if n <= 1000: return "101-1K"
    if n <= 10000: return "1K-10K"
    if n <= 100000: return "10K-100K"
    return ">100K"

bins = Counter()
for ds in datasets:
    bins[records_bin(ds.get("records_count", 0))] += 1

print("📏 DISTRIBUZIONE RECORDS")
for b in ["0", "1-10", "11-100", "101-1K", "1K-10K", "10K-100K", ">100K"]:
    print(f"   {b:10s} {bins[b]:4d}")
print()

# --- 6. FEATURES (timeserie, geo, analyze) ---
features = Counter()
for ds in datasets:
    for f in ds.get("features", []):
        features[f] += 1

print("⭐ FEATURES")
for f, n in features.most_common():
    print(f"   {f:15s} {n:4d}")
print()

# --- 7. KEYWORDS più comuni ---
keywords = Counter()
for ds in datasets:
    for kw in ds.get("keyword") or []:
        kw = kw.strip()
        if kw:
            keywords[kw] += 1

print("🔑 KEYWORDS (top 20)")
for kw, n in keywords.most_common(20):
    print(f"   {kw:40s} {n:4d}")
print()

# --- 8. TOP 20 DATASET per records ---
print("🏆 TOP 20 DATASET per numero di records")
sorted_ds = sorted(datasets, key=lambda x: x.get("records_count", 0), reverse=True)
for ds in sorted_ds[:20]:
    theme_str = ", ".join(ds.get("theme", []))[:40]
    print(f"   {ds['records_count']:>8d}  {ds['id']:50s}  [{theme_str}]")
print()

# --- 9. DATASET CON RECORDS=0 ---
zero = [ds for ds in datasets if ds.get("records_count", 0) == 0]
print(f"⚠️  Dataset senza records: {len(zero)}")
for ds in zero[:10]:
    print(f"   - {ds['id']}")
if len(zero) > 10:
    print(f"   ... e altri {len(zero)-10}")
print()

# --- 10. QUARTIERE-RELATED ---
quartieri = [ds for ds in datasets if 'quartiere' in ds['id'] or 'quartiere' in (ds.get('description','').lower())]
# meglio: dataset con 'quartiere' nel titolo o keyword
quartieri_keyword = [ds for ds in datasets if any('quartiere' in ds.get('title','').lower() or 'quartiere' in kw.lower() for kw in (ds.get('keyword') or []))]
print(f"🏘️  Dataset con riferimenti a quartieri: {len(quartieri_keyword)}")
print()

# --- 11. MOBILITÀ ---
mobilita = [ds for ds in datasets if any(t in (ds.get('theme') or []) for t in ['Trasporti'])]
print(f"🚗 Dataset tema Trasporti: {len(mobilita)}")
for ds in sorted(mobilita, key=lambda x: x.get("records_count", 0), reverse=True)[:10]:
    print(f"   {ds['records_count']:>8d}  {ds['id']}")
print()

# --- 12. Serie storiche ---
serie = [ds for ds in datasets if "timeserie" in ds.get("features", [])]
print(f"📈 Dataset con timeserie: {len(serie)}")
for ds in sorted(serie, key=lambda x: x.get("records_count", 0), reverse=True)[:15]:
    theme_str = ", ".join(ds.get("theme", []))[:30]
    print(f"   {ds['records_count']:>8d}  {ds['id']:50s}  [{theme_str}]")
print()

# --- 13. Dataset più recenti ---
recent = sorted(datasets, key=lambda x: x.get("modified", ""), reverse=True)
print(f"🆕 Dataset modificati più di recente (top 15)")
for ds in recent[:15]:
    print(f"   {ds['modified'][:10]:12s}  {ds['id']}")
print()

# --- 14. Dataset con geo ---
geo = [ds for ds in datasets if "geo" in ds.get("features", [])]
print(f"🗺️  Dataset con features geo: {len(geo)}")
