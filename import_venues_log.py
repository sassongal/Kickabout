import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import requests
from math import radians, cos, sin, asin, sqrt
import datetime
import sys
import os

# --- הגדרות ---
# אין צורך בקובץ מפתח יותר!
CITIES_TO_SCAN = ["Tel Aviv", "Haifa", "Jerusalem"] 
MIN_DISTANCE_METERS = 70  
LOG_FILENAME = "venueslist.md"

# --- פונקציית Geohash ---
__base32 = '0123456789bcdefghjkmnpqrstuvwxyz'
def encode_geohash(latitude, longitude, precision=12):
    lat_interval, lon_interval = (-90.0, 90.0), (-180.0, 180.0)
    geohash = []
    bits = [16, 8, 4, 2, 1]
    bit = 0
    ch = 0
    even = True
    while len(geohash) < precision:
        if even:
            mid = (lon_interval[0] + lon_interval[1]) / 2
            if longitude > mid:
                ch |= bits[bit]
                lon_interval = (mid, lon_interval[1])
            else:
                lon_interval = (lon_interval[0], mid)
        else:
            mid = (lat_interval[0] + lat_interval[1]) / 2
            if latitude > mid:
                ch |= bits[bit]
                lat_interval = (mid, lat_interval[1])
            else:
                lat_interval = (lat_interval[0], mid)
        even = not even
        if bit < 4:
            bit += 1
        else:
            geohash += __base32[ch]
            bit = 0
            ch = 0
    return ''.join(geohash)

# --- חישוב מרחק ---
def calculate_distance(lat1, lon1, lat2, lon2):
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371
    return c * r * 1000

# --- התחלה ---
print(f"🚀 Initializing Kattrick Venue Importer (GCloud Mode)...")

try:
    # שינוי קריטי: חיבור ללא מפתח, באמצעות האימות שעשית בטרמינל
    firebase_admin.initialize_app()
    db = firestore.client()
    print("✅ Connected to Firestore successfully.")
except Exception as e:
    print(f"❌ Connection Failed: {e}")
    print("   Make sure you ran 'gcloud auth application-default login' in terminal.")
    sys.exit(1)

# 1. טעינת נתונים קיימים
existing_venues_locs = [] 
existing_osm_ids = set()

print("📚 Loading existing venues to prevent duplicates...")
try:
    docs = db.collection('venues').stream()
    for doc in docs:
        data = doc.to_dict()
        loc = data.get('location')
        if loc:
            existing_venues_locs.append({'lat': loc.latitude, 'lon': loc.longitude})
        ext_id = data.get('externalId')
        if ext_id:
            existing_osm_ids.add(str(ext_id))
    print(f"✅ Loaded {len(existing_venues_locs)} existing venues.")
except Exception as e:
    print(f"⚠️ Warning: Could not read existing venues ({e}). Assuming DB is empty.")

# 2. שאילתה ל-OpenStreetMap
cities_query_part = ""
for city in CITIES_TO_SCAN:
    cities_query_part += f'area["name:en"="{city}"]->.searchArea; (node["sport"="soccer"](area.searchArea); way["sport"="soccer"](area.searchArea);); '

query = f"""
[out:json][timeout:60];
(
  {cities_query_part}
);
out center;
"""

print(f"🌍 Fetching data for: {', '.join(CITIES_TO_SCAN)}...")
try:
    response = requests.get("http://overpass-api.de/api/interpreter", params={'data': query})
    if response.status_code != 200:
        raise Exception(f"OSM API returned {response.status_code}")
    data = response.json()
    elements = data.get('elements', [])
    print(f"📍 Found {len(elements)} candidates in OSM.")
except Exception as e:
    print(f"❌ Error fetching from OSM: {e}")
    sys.exit(1)

# 3. עיבוד ושמירה
with open(LOG_FILENAME, 'w', encoding='utf-8') as log_file:
    log_file.write(f"# Kattrick Import Log\n")
    log_file.write(f"**Date:** {datetime.datetime.now()}\n\n")
    
    batch = db.batch()
    batch_count = 0
    imported_count = 0
    skipped_count = 0

    for element in elements:
        osm_id = str(element['id'])
        
        if osm_id in existing_osm_ids:
            skipped_count += 1
            continue

        lat = element.get('lat') or element.get('center', {}).get('lat')
        lon = element.get('lon') or element.get('center', {}).get('lon')
        
        if not lat or not lon:
            continue

        is_duplicate_dist = False
        for existing in existing_venues_locs:
            dist = calculate_distance(lat, lon, existing['lat'], existing['lon'])
            if dist < MIN_DISTANCE_METERS:
                skipped_count += 1
                is_duplicate_dist = True
                break
        
        if is_duplicate_dist:
            continue

        tags = element.get('tags', {})
        facilities = []
        if tags.get('lit') == 'yes': facilities.append('lighting')
        if tags.get('shower') == 'yes': facilities.append('showers')
        if tags.get('parking') == 'yes': facilities.append('parking')
        
        raw_surface = tags.get('surface', 'unknown')
        final_surface = raw_surface if raw_surface in ['grass', 'artificial_turf', 'concrete', 'sand'] else 'unknown'

        address_parts = []
        if 'addr:street' in tags: address_parts.append(tags['addr:street'])
        if 'addr:housenumber' in tags: address_parts.append(tags['addr:housenumber'])
        osm_address = ", ".join(address_parts) if address_parts else ""

        venue_name = tags.get('name', tags.get('name:he', tags.get('name:en', 'מגרש כדורגל ציבורי')))
        
        venue_id = f"osm_{osm_id}"
        g_hash = encode_geohash(lat, lon)

        venue_data = {
            'venueId': venue_id,
            'externalId': osm_id,
            'name': venue_name,
            'description': 'מגרש ציבורי (מקור: OpenStreetMap)',
            'location': firestore.GeoPoint(lat, lon),
            'geohash': g_hash,
            'address': osm_address,
            'images': [],
            'facilities': facilities,
            'surface': final_surface,
            'isPublic': True,
            'pricePerHour': 0,
            'isActive': True,
            'source': 'osm',
            'rating': 0.0,
            'ratingCount': 0,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }

        doc_ref = db.collection('venues').document(venue_id)
        batch.set(doc_ref, venue_data)
        
        log_file.write(f"* Added: {venue_name} ({lat}, {lon})\n")
        
        batch_count += 1
        imported_count += 1

        if batch_count >= 400:
            batch.commit()
            print(f"💾 Saved batch of {batch_count}...")
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

print("-" * 30)
print(f"✅ DONE! Imported: {imported_count}, Skipped: {skipped_count}")
print(f"📄 Log file: {LOG_FILENAME}")