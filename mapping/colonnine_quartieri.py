#!/usr/bin/env python3
"""
Mapping colonnine conta-bici → quartieri di Bologna.
Usa il dataset civici (rifter_civici_pt) per match spaziale approssimato.
Produce mapping/colonnine-quartieri.csv
"""
import os, sys, struct, csv, json, math

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE)

DATA_DIR = os.path.join(BASE, "_data")
MAPPING_DIR = os.path.join(BASE, "mapping")
os.makedirs(MAPPING_DIR, exist_ok=True)

CIVICI_PATH = os.path.join(DATA_DIR, "rifter-civici.parquet")
BICI_PATH = os.path.join(DATA_DIR, "colonnine-bici.parquet")
OUT_PATH = os.path.join(MAPPING_DIR, "colonnine-quartieri.csv")

def decode_geo_point(raw_bytes):
    """Decodifica geo_point_2d da WKB Point."""
    if len(raw_bytes) < 21:
        return None, None
    x = struct.unpack('<d', raw_bytes[5:13])[0]
    y = struct.unpack('<d', raw_bytes[13:21])[0]
    return x, y

def haversine(lon1, lat1, lon2, lat2):
    """Distanza in metri tra due coordinate."""
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def main():
    import duckdb
    con = duckdb.connect()
    
    # 1. Carica colonnine
    print("📥 Carico colonnine...")
    rows_bici = con.execute(f"""
        SELECT colonnina, geo_point_2d
        FROM read_parquet('{BICI_PATH}')
        GROUP BY colonnina, geo_point_2d
        ORDER BY colonnina
    """).fetchall()
    
    colonnine = []
    for name, raw in rows_bici:
        lon, lat = decode_geo_point(bytes(raw))
        if lon is not None:
            colonnine.append({"name": name, "lon": lon, "lat": lat})
    
    print(f"   {len(colonnine)} colonnine con coordinate")
    
    # 2. Carica civici con coordinate e quartiere
    print("📥 Carico civici...")
    
    # Se non esiste, avvisa
    if not os.path.exists(CIVICI_PATH):
        print("⚠️  Dataset civici (rifter) non trovato.")
        print("   I mapping già generati sono committati in mapping/*.csv e usati dai candidate.")
        print("   Per rigenerarli serve il dataset civici, non migrato nel toolkit.")
        return
    
    civici = con.execute(f"""
        SELECT denominazi, civico, quartiere, zona_nome, geo_point_2d
        FROM read_parquet('{CIVICI_PATH}')
        WHERE quartiere IS NOT NULL AND quartiere != ''
    """).fetchall()
    
    print(f"   {len(civici)} civici con quartiere")
    
    # 3. Per ogni colonnina, trova il civico più vicino (entro 200m)
    print("🔗 Matching colonnine → quartieri...")
    results = []
    not_found = []
    
    for c in colonnine:
        best_dist = 200  # soglia massima 200m
        best_match = None
        
        for row in civici:
            raw_geo = bytes(row[4]) if row[4] else None
            if not raw_geo or len(raw_geo) < 21:
                continue
            clon, clat = decode_geo_point(raw_geo)
            if clon is None:
                continue
            
            dist = haversine(c["lon"], c["lat"], clon, clat)
            if dist < best_dist:
                best_dist = dist
                best_match = {
                    "via": row[0],
                    "civico": row[1],
                    "quartiere": row[2],
                    "zona": row[3],
                    "distanza_m": round(dist, 1)
                }
        
        if best_match:
            results.append({
                "colonnina": c["name"],
                "lon": c["lon"],
                "lat": c["lat"],
                "quartiere": best_match["quartiere"],
                "zona": best_match["zona"],
                "via": best_match["via"],
                "civico": best_match["civico"],
                "distanza_m": best_match["distanza_m"]
            })
            print(f"   ✅ {c['name']:20s} → {best_match['quartiere']:25s} ({best_match['zona']:15s}) a {best_match['distanza_m']:.0f}m")
        else:
            not_found.append(c["name"])
            print(f"   ⚠️  {c['name']:20s} → nessun civico entro 200m")
    
    # 4. Salva mapping
    with open(OUT_PATH, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["colonnina", "lon", "lat", "quartiere", "zona", "via", "civico", "distanza_m"])
        writer.writeheader()
        writer.writerows(results)
    
    print(f"\n💾 Salvato: {OUT_PATH}")
    print(f"   Mappate: {len(results)}/{len(colonnine)}")
    if not_found:
        print(f"   Non trovate: {', '.join(not_found)}")

if __name__ == "__main__":
    main()
