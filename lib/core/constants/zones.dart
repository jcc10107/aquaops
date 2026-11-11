import 'package:latlong2/latlong.dart';

// Single source of truth for San Pablo City barangay/zone data, shared by
// the POS screen, the dispatch queue, and customer checkout. This list is
// copied exactly from saved_addresses_screen.dart's `_barangays` constant —
// that screen is the authoritative source. Four legacy barangays keep their
// original short codes (si/dr/sr/sm) everywhere stock routing already
// depends on them; every other barangay is stored as its real official
// name — no invented codes, no migration needed for existing order data.

// Approximate official boundary of San Pablo City, simplified (Douglas-Peucker,
// ~0.0007°) from OpenStreetMap's administrative boundary (relation 6490067) to
// keep this list a manageable size. Used only to draw a reference outline on
// the delivery map pickers — not for precise point-in-polygon checks.
final List<LatLng> sanPabloCityBoundary = [
  LatLng(13.992521, 121.244500),
  LatLng(13.988472, 121.253467),
  LatLng(13.990334, 121.259921),
  LatLng(13.981057, 121.260051),
  LatLng(13.973980, 121.256270),
  LatLng(13.967342, 121.256817),
  LatLng(13.968755, 121.262887),
  LatLng(13.966778, 121.268482),
  LatLng(13.969795, 121.270868),
  LatLng(13.970615, 121.274085),
  LatLng(13.974386, 121.278377),
  LatLng(13.972879, 121.280965),
  LatLng(13.975027, 121.286548),
  LatLng(13.972939, 121.289894),
  LatLng(13.972166, 121.295173),
  LatLng(13.974998, 121.295150),
  LatLng(13.976453, 121.300808),
  LatLng(13.981307, 121.306271),
  LatLng(13.981058, 121.312266),
  LatLng(13.985240, 121.321928),
  LatLng(13.984155, 121.324027),
  LatLng(13.985760, 121.329263),
  LatLng(13.987889, 121.330886),
  LatLng(13.991122, 121.331193),
  LatLng(13.995806, 121.336210),
  LatLng(14.000671, 121.337840),
  LatLng(14.003192, 121.340031),
  LatLng(14.006610, 121.346946),
  LatLng(14.008723, 121.347533),
  LatLng(14.011904, 121.350805),
  LatLng(14.017233, 121.359409),
  LatLng(14.023141, 121.376219),
  LatLng(14.023463, 121.378424),
  LatLng(14.022018, 121.380166),
  LatLng(14.033628, 121.392809),
  LatLng(14.034397, 121.398835),
  LatLng(14.036727, 121.405027),
  LatLng(14.035862, 121.405021),
  LatLng(14.035979, 121.406358),
  LatLng(14.044859, 121.420362),
  LatLng(14.051808, 121.426724),
  LatLng(14.054360, 121.426235),
  LatLng(14.063404, 121.430913),
  LatLng(14.068563, 121.402102),
  LatLng(14.078023, 121.398121),
  LatLng(14.092314, 121.390497),
  LatLng(14.095130, 121.387736),
  LatLng(14.100999, 121.385397),
  LatLng(14.102136, 121.384114),
  LatLng(14.101767, 121.380779),
  LatLng(14.104672, 121.381347),
  LatLng(14.106025, 121.378943),
  LatLng(14.108462, 121.380656),
  LatLng(14.111839, 121.379857),
  LatLng(14.111665, 121.378800),
  LatLng(14.116389, 121.374355),
  LatLng(14.117036, 121.371294),
  LatLng(14.121216, 121.369273),
  LatLng(14.122943, 121.365406),
  LatLng(14.125439, 121.364403),
  LatLng(14.127479, 121.361694),
  LatLng(14.127620, 121.360080),
  LatLng(14.129982, 121.358916),
  LatLng(14.130941, 121.356932),
  LatLng(14.134672, 121.357607),
  LatLng(14.135684, 121.356425),
  LatLng(14.135263, 121.351318),
  LatLng(14.142252, 121.345868),
  LatLng(14.146646, 121.344911),
  LatLng(14.138636, 121.340571),
  LatLng(14.127185, 121.327624),
  LatLng(14.122162, 121.324642),
  LatLng(14.120137, 121.319189),
  LatLng(14.115195, 121.320605),
  LatLng(14.111783, 121.316384),
  LatLng(14.108776, 121.311872),
  LatLng(14.116539, 121.296723),
  LatLng(14.108691, 121.288172),
  LatLng(14.106132, 121.287088),
  LatLng(14.099103, 121.280520),
  LatLng(14.094951, 121.279147),
  LatLng(14.087139, 121.270194),
  LatLng(14.082583, 121.271447),
  LatLng(14.082979, 121.272660),
  LatLng(14.078213, 121.274337),
  LatLng(14.076064, 121.273597),
  LatLng(14.072834, 121.274968),
  LatLng(14.071991, 121.276311),
  LatLng(14.073116, 121.279031),
  LatLng(14.069726, 121.281898),
  LatLng(14.068400, 121.281705),
  LatLng(14.068890, 121.284179),
  LatLng(14.067618, 121.284795),
  LatLng(14.067998, 121.285729),
  LatLng(14.066712, 121.285704),
  LatLng(14.067296, 121.287246),
  LatLng(14.064585, 121.288250),
  LatLng(14.064283, 121.287272),
  LatLng(14.062105, 121.287412),
  LatLng(14.057659, 121.289646),
  LatLng(14.056774, 121.288410),
  LatLng(14.053287, 121.290115),
  LatLng(14.049464, 121.283770),
  LatLng(14.047185, 121.284380),
  LatLng(14.043743, 121.277711),
  LatLng(14.040756, 121.278812),
  LatLng(14.039234, 121.277697),
  LatLng(14.035344, 121.279203),
  LatLng(14.032299, 121.276470),
  LatLng(14.030925, 121.278004),
  LatLng(14.028313, 121.276794),
  LatLng(14.026387, 121.277784),
  LatLng(14.022869, 121.273994),
  LatLng(14.021859, 121.274726),
  LatLng(14.020006, 121.271078),
  LatLng(14.011604, 121.262800),
  LatLng(14.011736, 121.259601),
  LatLng(13.992521, 121.244500),
];

const List<String> sanPabloBarangays = [
  'Barangay I-A (Sambat)',
  'Barangay I-B',
  'Barangay II-A',
  'Barangay II-B',
  'Barangay II-C',
  'Barangay II-D',
  'Barangay II-E',
  'Barangay II-F',
  'Barangay III-A',
  'Barangay III-B',
  'Barangay III-C',
  'Barangay III-D',
  'Barangay III-E',
  'Barangay IV-A',
  'Barangay IV-B',
  'Barangay IV-C',
  'Barangay V-A',
  'Barangay V-B',
  'Barangay V-C',
  'Barangay V-D',
  'Barangay VI-A',
  'Barangay VI-B',
  'Barangay VI-C',
  'Barangay VI-D',
  'Barangay VI-E',
  'Barangay VII-A',
  'Barangay VII-B',
  'Barangay VII-C',
  'Barangay VII-D',
  'Barangay VII-E',
  'Barangay Bagong Bayan (Poblacion)',
  'Barangay Atisan',
  'Barangay Bautista',
  'Barangay Concepcion',
  'Barangay Del Remedio',
  'Barangay Dolores',
  'Barangay San Antonio 1',
  'Barangay San Antonio 2',
  'Barangay San Bartolome',
  'Barangay San Buenaventura',
  'Barangay San Crispin',
  'Barangay San Cristobal',
  'Barangay San Diego',
  'Barangay San Francisco',
  'Barangay San Gabriel',
  'Barangay San Gregorio',
  'Barangay San Ignacio',
  'Barangay San Isidro',
  'Barangay San Joaquin',
  'Barangay San Jose',
  'Barangay San Juan',
  'Barangay San Lorenzo',
  'Barangay San Lucas 1',
  'Barangay San Lucas 2',
  'Barangay San Marcos',
  'Barangay San Mateo',
  'Barangay San Miguel',
  'Barangay San Nicolas',
  'Barangay San Pedro',
  'Barangay San Rafael',
  'Barangay San Roque',
  'Barangay San Vicente',
  'Barangay Santa Ana',
  'Barangay Santa Catalina',
  'Barangay Santa Cruz',
  'Barangay Santa Elena',
  'Barangay Santa Felomina',
  'Barangay Santa Isabel',
  'Barangay Santa Maria',
  'Barangay Santa Maria Magdalena',
  'Barangay Santa Monica',
  'Barangay Santa Veronica',
  'Barangay Santiago 1',
  'Barangay Santiago 2',
  'Barangay Santisimo Rosario',
  'Barangay Santo Angel',
  'Barangay Santo Cristo',
  'Barangay Santo Niño',
  'Barangay Soledad',
];

// The 4 legacy short codes and the exact official barangay name each maps to.
const Map<String, String> sanPabloZoneCodes = {
  'si': 'Barangay San Isidro',
  'dr': 'Barangay Del Remedio',
  'sr': 'Barangay San Roque',
  'sm': 'Barangay San Marcos',
};

String _normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _stripPrefix(String barangayName) {
  return barangayName.startsWith('Barangay ') ? barangayName.substring(9) : barangayName;
}

String? _codeForBarangayName(String fullName) {
  final norm = _normalize(fullName);
  for (final entry in sanPabloZoneCodes.entries) {
    if (_normalize(entry.value) == norm) return entry.key;
  }
  return null;
}

/// Normalizes a raw barangay value OR a free-text delivery address into a
/// stored zone value: one of the 4 short codes (si/dr/sr/sm), the full
/// official name of any other barangay, or 'other' as a last resort when
/// nothing can be matched.
String zoneGroupOf(String rawBarangayOrAddressText) {
  final raw = rawBarangayOrAddressText.trim();
  if (raw.isEmpty) return 'other';

  // Already a stored code — pass through.
  if (sanPabloZoneCodes.containsKey(raw)) return raw;

  // Exact match against the official list (common case: a real barangay
  // name/value was passed directly, e.g. from a dropdown).
  for (final b in sanPabloBarangays) {
    if (_normalize(b) == _normalize(raw)) {
      return _codeForBarangayName(b) ?? b;
    }
  }

  final lower = raw.toLowerCase();

  // Free-text address: look specifically for "Barangay <Name>" / "Brgy
  // <Name>" so a street name that happens to share words with a barangay
  // (e.g. "San Marcos St") doesn't falsely match that barangay instead of
  // the one actually labeled in the address.
  final labeledMatch = RegExp(r'(?:barangay|brgy\.?)\s+([a-z0-9\s\-\(\)ñ]+)').firstMatch(lower);
  if (labeledMatch != null) {
    final candidate = _normalize(labeledMatch.group(1)!);
    for (final b in sanPabloBarangays) {
      final bName = _normalize(_stripPrefix(b));
      if (candidate.startsWith(bName) || bName.startsWith(candidate)) {
        return _codeForBarangayName(b) ?? b;
      }
    }
  }

  // Last resort: plain substring match, longest barangay name first so a
  // more specific name (e.g. "Santa Maria Magdalena") wins over a shorter
  // one that happens to be its prefix (e.g. "Santa Maria").
  final sortedByLength = [...sanPabloBarangays]..sort((a, b) => b.length.compareTo(a.length));
  for (final b in sortedByLength) {
    final bName = _normalize(_stripPrefix(b));
    if (lower.contains(bName)) {
      return _codeForBarangayName(b) ?? b;
    }
  }

  return 'other';
}

/// Turns a stored zone value (a code, a full barangay name, or 'other')
/// into a human-readable label for display to riders/staff.
String zoneLabel(String zoneValue) {
  if (sanPabloZoneCodes.containsKey(zoneValue)) {
    return _stripPrefix(sanPabloZoneCodes[zoneValue]!);
  }
  if (zoneValue.trim().isEmpty || zoneValue == 'other') return 'Other Barangay';
  return _stripPrefix(zoneValue);
}

class ZoneOption {
  final String label;
  final String value;
  const ZoneOption(this.label, this.value);
}

/// All ~80 barangays as (label, value) pairs for a dropdown — the 4 legacy
/// barangays use their short code as the value, every other barangay uses
/// its own full official name as both label (minus the "Barangay " prefix)
/// and value.
List<ZoneOption> buildZoneOptions() {
  return sanPabloBarangays.map((b) {
    final code = _codeForBarangayName(b);
    return ZoneOption(_stripPrefix(b), code ?? b);
  }).toList();
}

// Placeholder station/hub coordinates (San Pablo City, Laguna center-point)
// used as the delivery route's origin on the live tracking map. There's no
// stored station address/coordinate anywhere in this app yet — replace with
// the real refilling station location once that becomes configurable.
const double stationLat = 14.0683;
const double stationLng = 121.3256;
