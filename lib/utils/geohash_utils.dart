/// Simple Geohash implementation for location-based queries
/// Based on: https://en.wikipedia.org/wiki/Geohash
class GeohashUtils {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const List<int> _bits = [16, 8, 4, 2, 1];

  /// Encode latitude and longitude to geohash
  static String encode(double latitude, double longitude, {int precision = 8}) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    bool even = true;
    int bit = 0;
    int ch = 0;
    String geohash = '';

    while (geohash.length < precision) {
      if (even) {
        double mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          ch |= _bits[bit];
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        double mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= _bits[bit];
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return geohash;
  }

  /// Decode geohash to latitude and longitude
  static Map<String, double> decode(String geohash) {
    bool even = true;
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    for (int i = 0; i < geohash.length; i++) {
      int ch = _base32.indexOf(geohash[i]);
      for (int j = 0; j < 5; j++) {
        int mask = _bits[j];
        if (even) {
          double mid = (lonMin + lonMax) / 2;
          if ((ch & mask) != 0) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          double mid = (latMin + latMax) / 2;
          if ((ch & mask) != 0) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        even = !even;
      }
    }

    return {
      'latitude': (latMin + latMax) / 2,
      'longitude': (lonMin + lonMax) / 2,
    };
  }

  /// Get neighbors of a geohash (8 surrounding geohashes)
  static List<String> neighbors(String geohash) {
    final decoded = decode(geohash);
    final lat = decoded['latitude']!;
    final lon = decoded['longitude']!;
    final precision = geohash.length;

    // Calculate approximate cell size
    final latDelta = 180.0 / (1 << (5 * precision ~/ 2));
    final lonDelta = 360.0 / (1 << (5 * precision ~/ 2));

    return [
      encode(lat, lon + lonDelta, precision: precision), // East
      encode(lat, lon - lonDelta, precision: precision), // West
      encode(lat + latDelta, lon, precision: precision), // North
      encode(lat - latDelta, lon, precision: precision), // South
      encode(lat + latDelta, lon + lonDelta, precision: precision), // Northeast
      encode(lat + latDelta, lon - lonDelta, precision: precision), // Northwest
      encode(lat - latDelta, lon + lonDelta, precision: precision), // Southeast
      encode(lat - latDelta, lon - lonDelta, precision: precision), // Southwest
    ];
  }
}

