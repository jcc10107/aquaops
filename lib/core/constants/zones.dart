// Single source of truth for San Pablo City barangay/zone data, shared by
// the POS screen, the dispatch queue, and customer checkout. This list is
// copied exactly from saved_addresses_screen.dart's `_barangays` constant —
// that screen is the authoritative source. Four legacy barangays keep their
// original short codes (si/dr/sr/sm) everywhere stock routing already
// depends on them; every other barangay is stored as its real official
// name — no invented codes, no migration needed for existing order data.

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
