import 'package:basic_app/core/config/env/app_env.dart';
import 'package:basic_app/features/movies/data/models/omdb_api_models.dart';
import 'package:dio/dio.dart';

/// One logical "trending" page: OMDB only allows one [s] per HTTP call, so we run several
/// searches in parallel with the same [page] and merge (deterministic round-robin + dedupe).
typedef OmdbTrendingFetchResult = ({
  List<OmdbSearchItemDto> items,
  bool hasMore,
});

class MovieRemoteSource {
  MovieRemoteSource(Dio dio)
      : _omdbDio = Dio(
          dio.options.copyWith(
            baseUrl: AppEnv.omdbBaseUrl,
            queryParameters: {'apikey': AppEnv.omdbApiKey},
          ),
        )..interceptors.addAll(dio.interceptors);

  final Dio _omdbDio;

  /// Shared catalogue: same queries and [page] for every client → same merged ordering.
  static const List<String> trendingSearchQueries = <String>[
    'action',
    'thriller',
    'comedy',
    'drama',
    'sci-fi',
  ];

  Future<OmdbTrendingFetchResult> fetchTrendingMovies({required int page}) async {
    final lists = await Future.wait(
      trendingSearchQueries.map((query) => _fetchSearchPage(query: query, page: page)),
    );

    final hasMore = lists.any((list) => list.length >= _omdbMaxHitsPerPage);
    final merged = _mergeRoundRobinDedupe(lists);

    return (items: merged, hasMore: hasMore);
  }

  static const int _omdbMaxHitsPerPage = 10;

  Future<List<OmdbSearchItemDto>> _fetchSearchPage({
    required String query,
    required int page,
  }) async {
    try {
      final response = await _omdbDio.get(
        '',
        queryParameters: {
          's': query,
          'page': page,
        },
      );
      final raw = response.data;
      if (raw is! Map) {
        return [];
      }
      final data = (raw['Search'] as List<dynamic>? ?? []);
      return data
          .map((e) => OmdbSearchItemDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException {
      return [];
    } on FormatException {
      return [];
    }
  }

  /// Preserves a stable mix: 1st hit from each query, then 2nd from each, …; skips duplicate imdbIDs.
  static List<OmdbSearchItemDto> _mergeRoundRobinDedupe(List<List<OmdbSearchItemDto>> lists) {
    if (lists.isEmpty) return [];

    final seenIds = <String>{};
    final out = <OmdbSearchItemDto>[];
    final maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < maxLen; i++) {
      for (final list in lists) {
        if (i >= list.length) continue;
        final id = list[i].imdbID.trim();
        if (id.isEmpty) continue;
        if (seenIds.add(id)) out.add(list[i]);
      }
    }
    return out;
  }

  /// `?i=tt3896198` — full plot, ratings, etc.
  Future<OmdbMovieDetailDto> fetchOmdbMovieDetail({required String imdbId}) async {
    final response = await _omdbDio.get(
      '',
      queryParameters: {
        'i': imdbId,
      },
    );
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('OMDB detail: expected JSON object');
    }
    return OmdbMovieDetailDto.fromJson(Map<String, dynamic>.from(raw));
  }
}
