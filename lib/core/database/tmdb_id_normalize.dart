/// Normalizes OMDB / IMDb identifiers to `tt1234567` form for [Movies.tmdbId].
String normalizeTmdbId(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final lower = t.toLowerCase();
  if (lower.startsWith('tt')) return t;
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  return 'tt$digits';
}
