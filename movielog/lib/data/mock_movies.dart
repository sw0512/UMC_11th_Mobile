import '../models/movie.dart';

const mockMovies = <Movie>[
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genres: ['로맨스', '드라마'],
    year: 2026,
    runningTime: 120,
    posterAssetPath: 'assets/images/posters/hero_under_the_starlight.jpg',
    synopsis: '별이 쏟아지는 밤, 서로 다른 시간을 살아온 두 사람이 우연한 만남을 통해 서로의 마음을 알아가는 이야기입니다.',
    averageRating: 4.5,
  ),
  Movie(
    id: 2,
    title: '심연을 걷는 자',
    genres: ['드라마'],
    year: 2026,
    runningTime: 114,
    posterAssetPath: 'assets/images/posters/poster_abyss_walker.jpg',
    synopsis: '깊은 심연에 남겨진 기억을 따라 한 걸음씩 앞으로 나아가는 사람들의 이야기입니다.',
    averageRating: 4.2,
  ),
  Movie(
    id: 3,
    title: '공허의 메아리',
    genres: ['SF'],
    year: 2025,
    runningTime: 131,
    posterAssetPath: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    synopsis: '알 수 없는 신호를 쫓던 탐사대가 우주에서 발견한 미지의 메아리를 그립니다.',
    averageRating: 4.0,
  ),
  Movie(
    id: 4,
    title: '네 번째 오후',
    genres: ['드라마'],
    year: 2026,
    runningTime: 108,
    posterAssetPath: 'assets/images/posters/poster_fourth_afternoon.jpg',
    synopsis: '반복되는 오후 속에서 가장 소중한 순간의 의미를 찾아가는 이야기입니다.',
    averageRating: 4.3,
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genres: ['스릴러'],
    year: 2025,
    runningTime: 116,
    posterAssetPath: 'assets/images/posters/poster_night_shadows.jpg',
    synopsis: '도시의 어두운 골목마다 남겨진 흔적을 추적하는 미스터리 스릴러입니다.',
    averageRating: 3.9,
  ),
];

Movie? findMovieById(int id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
