class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;
  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) => TmdbMovieDto(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '제목 없음',
    overview: json['overview'] as String? ?? '',
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    releaseDate: json['release_date'] as String?,
    genreIds: List.unmodifiable(
      (json['genre_ids'] as List? ??
              (json['genres'] as List?)
                  ?.map((g) => (g as Map<String, dynamic>)['id'])
                  .toList() ??
              [])
          .map((v) => (v as num).toInt()),
    ),
    voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
    popularity: (json['popularity'] as num? ?? 0).toDouble(),
  );
}
