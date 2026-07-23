#!/usr/bin/env python3
"""
Mapping varchi ZTL → quartieri di Bologna.
Usa il dataset civici (rifter_civici_pt) per match spaziale.
"""
import os, sys, struct, csv, math
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)

DATA_DIR = os.path.join(BASE, "_data")
MAPPING_DIR = os.path.join(BASE, "mapping")
CIVICI_PATH = os.path.join(DATA_DIR, "rifter-civici.parquet")

def decode_geo(raw_bytes):
    if raw_bytes is None: return None, None
    raw = bytes(raw_bytes) if not isinstance(raw_bytes, bytes) else raw_bytes
    if len(raw) < 21: return None, None
    x = struct.unpack('<d', raw[5:13])[0]
    y = struct.unpack('<d', raw[13:21])[0]
    return x, y

def haversine(lon1, lat1, lon2, lat2):
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

import duckdb
con = duckdb.connect()

# Tutti i varchi dal catalogo
import json
with open(os.path.join(BASE, "catalog_full.json")) as f:
    cat = json.load(f)

varchi = [ds for ds in cat["datasets"] if ds["id"].startswith("varco-n-")]
print(f"Varchi ZTL trovati: {len(varchi)}")

# Per ogni varco, prendi nome e coordinate via API (solo prime righe)
# Usiamo i dati dal dataset varco-ercolani come template
# Invece di scaricare tutti i varchi, prendiamo le info dal catalogo

# Scarichiamo un dataset unico con tutti i varchi? No, sono separati.
# Usiamo il nome del varco per fare mapping manuale + coordinate

# Per ora, mappiamo i varchi di cui abbiamo il parquet (varco-ercolani)
# e per gli altri usiamo le coordinate dalla descrizione nel catalogo

# Carica civici
civici = con.execute(f"""
    SELECT denominazi, civico, quartiere, zona_nome, geo_point_2d
    FROM read_parquet('{CIVICI_PATH}')
    WHERE quartiere IS NOT NULL AND quartiere != ''
""").fetchall()
print(f"Civici caricati: {len(civici)}")

# Per ogni varco, prendi coordinate via API (1 chiamata per varco)
import urllib.request, json, time
api_base = "https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets"

varco_data = []
for v in varchi:
    ds_id = v["id"]
    url = f"{api_base}/{ds_id}/records?limit=1"
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
    except Exception as e:
        print(f"  ⚠️  {ds_id}: {e}")
        continue
    time.sleep(0.15)
    
    if data["results"]:
        row = data["results"][0]
        varco_data.append({
            "ds_id": ds_id,
            "nome_varco": row.get("nome_varco", ""),
            "descrizione": row.get("descrizione", ""),
            "direzione": row.get("direzione", ""),
            "coordinate": row.get("coordinate") or row.get("geo_point_2d"),
        })

print(f"\nVarchi con dati: {len(varco_data)}")
if not varco_data:
    print("❌ Nessun varco recuperabile. Esco.")
    sys.exit(1)

results = []
for v in varco_data:
    ds_id = v["ds_id"]
    geo = v.get("coordinate")
    if not geo:
        continue
    
    if isinstance(geo, dict) and "lon" in geo and "lat" in geo:
        lon, lat = geo["lon"], geo["lat"]
    elif isinstance(geo, (bytes, bytearray, list)):
        lon, lat = decode_geo(bytes(geo))
    else:
        continue
    if lon is None: continue
    
    # Nearest civico
    best_dist, best = 500, None
    for c in civici:
        clon, clat = decode_geo(c[4])
        if clon is None: continue
        dist = haversine(lon, lat, clon, clat)
        if dist < best_dist:
            best_dist = dist
            best = {"via": c[0], "civico": c[1], "quartiere": c[2], "zona": c[3]}
    
    if best:
        results.append({
            "varco": ds_id,
            "nome": v.get("nome_varco",""), 
            "descrizione": v.get("descrizione",""), 
            "direzione": v.get("direzione",""),
            "lon": lon, "lat": lat,
            "quartiere": best["quartiere"], "zona": best["zona"],
            "via": best["via"], "distanza_m": round(best_dist, 1)
        })
        print(f"  ✅ {ds_id:50s} → {best['quartiere']:25s} ({best['zona']:15s}) a {best_dist:.0f}m")

out = os.path.join(MAPPING_DIR, "varchi-quartieri.csv")
with open(out, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["varco","nome","descrizione","direzione","lon","lat","quartiere","zona","via","distanza_m"])
    w.writeheader()
    w.writerows(results)

print(f"\n💾 Salvato: {out} — {len(results)} varchi mappati")
