class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genres,
    required this.year,
    required this.runningTime,
    required this.posterAssetPath,
    required this.synopsis,
    required this.averageRating,
  });

  final int id;
  final String title;
  final List<String> genres;
  final int year;
  final int runningTime;
  final String posterAssetPath;
  final String synopsis;
  final double averageRating;

  String get genreLabel => genres.join(' · ');
}
