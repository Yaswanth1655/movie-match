// Models for http://www.omdbapi.com/ (search + title/detail by `i=`).

class OmdbRatingDto {
  const OmdbRatingDto({required this.source, required this.value});

  final String source;
  final String value;

  factory OmdbRatingDto.fromJson(Map<String, dynamic> json) {
    return OmdbRatingDto(
      source: json['Source']?.toString() ?? '',
      value: json['Value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'Source': source, 'Value': value};
}

/// One row from `Search` in `?s=` list responses.
class OmdbSearchItemDto {
  const OmdbSearchItemDto({
    required this.title,
    required this.year,
    required this.imdbID,
    required this.poster,
    required this.type,
  });

  final String title;
  final String year;
  final String imdbID;
  final String poster;
  final String type;

  factory OmdbSearchItemDto.fromJson(Map<String, dynamic> json) {
    return OmdbSearchItemDto(
      title: json['Title']?.toString() ?? '',
      year: json['Year']?.toString() ?? '',
      imdbID: json['imdbID']?.toString() ?? '',
      poster: json['Poster']?.toString() ?? '',
      type: json['Type']?.toString() ?? '',
    );
  }

  /// Numeric id aligned with existing app logic (digits from imdb id).
  int get numericMovieId {
    final digits = imdbID.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Shape persisted in [Movies.rawPayload] + used for list upsert.
  Map<String, dynamic> toStoredMovieRow() {
    final p = poster == 'N/A' ? '' : poster;
    return {
      'tmdbId': imdbID,
      'title': title,
      'overview': type,
      'poster_path': p,
      'release_date': year,
      'source': 'omdb',
      'imdbID': imdbID,
    };
  }
}

/// Full movie / episode object from `?i={imdbId}` (and same shape for some errors).
class OmdbMovieDetailDto {
  const OmdbMovieDetailDto({
    this.title,
    this.year,
    this.rated,
    this.released,
    this.runtime,
    this.genre,
    this.director,
    this.writer,
    this.actors,
    this.plot,
    this.language,
    this.country,
    this.awards,
    this.poster,
    this.ratings = const [],
    this.metascore,
    this.imdbRating,
    this.imdbVotes,
    this.imdbID,
    this.type,
    this.dvd,
    this.boxOffice,
    this.production,
    this.website,
    this.response,
  });

  final String? title;
  final String? year;
  final String? rated;
  final String? released;
  final String? runtime;
  final String? genre;
  final String? director;
  final String? writer;
  final String? actors;
  final String? plot;
  final String? language;
  final String? country;
  final String? awards;
  final String? poster;
  final List<OmdbRatingDto> ratings;
  final String? metascore;
  final String? imdbRating;
  final String? imdbVotes;
  final String? imdbID;
  final String? type;
  final String? dvd;
  final String? boxOffice;
  final String? production;
  final String? website;
  final String? response;

  bool get isSuccess => response?.toLowerCase() == 'true';

  factory OmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    final rawRatings = json['Ratings'] as List<dynamic>? ?? [];
    return OmdbMovieDetailDto(
      title: json['Title']?.toString(),
      year: json['Year']?.toString(),
      rated: json['Rated']?.toString(),
      released: json['Released']?.toString(),
      runtime: json['Runtime']?.toString(),
      genre: json['Genre']?.toString(),
      director: json['Director']?.toString(),
      writer: json['Writer']?.toString(),
      actors: json['Actors']?.toString(),
      plot: json['Plot']?.toString(),
      language: json['Language']?.toString(),
      country: json['Country']?.toString(),
      awards: json['Awards']?.toString(),
      poster: json['Poster']?.toString(),
      ratings: rawRatings
          .map((e) => OmdbRatingDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      metascore: json['Metascore']?.toString(),
      imdbRating: json['imdbRating']?.toString(),
      imdbVotes: json['imdbVotes']?.toString(),
      imdbID: json['imdbID']?.toString(),
      type: json['Type']?.toString(),
      dvd: json['DVD']?.toString(),
      boxOffice: json['BoxOffice']?.toString(),
      production: json['Production']?.toString(),
      website: json['Website']?.toString(),
      response: json['Response']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Title': title,
        'Year': year,
        'Rated': rated,
        'Released': released,
        'Runtime': runtime,
        'Genre': genre,
        'Director': director,
        'Writer': writer,
        'Actors': actors,
        'Plot': plot,
        'Language': language,
        'Country': country,
        'Awards': awards,
        'Poster': poster,
        'Ratings': ratings.map((e) => e.toJson()).toList(),
        'Metascore': metascore,
        'imdbRating': imdbRating,
        'imdbVotes': imdbVotes,
        'imdbID': imdbID,
        'Type': type,
        'DVD': dvd,
        'BoxOffice': boxOffice,
        'Production': production,
        'Website': website,
        'Response': response,
      };
}
