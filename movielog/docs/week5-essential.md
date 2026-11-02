# 5주차 실습 (Essential · Guided · Required · Challenge)

## 구성

- `core/config`: `.env`의 개인 TMDB Read Access Token 읽기
- `core/network`: TMDB 전용 Dio Client와 디버그 전용 마스킹 로그
- `data/models`, `data/services`: 순수 DTO와 stateless API Service
- `view_models`: 화면별 ChangeNotifier와 요청/상태 정책
- `widgets/movie_list/genre_filter_sheet.dart`: 확인 시에만 반영하는 다중 선택 BottomSheet

Popular는 앞 5개, Discover는 ID 중복을 제거하며 최대 30개까지 페이지를 수집합니다.
선택된 장르들은 `|`로 연결해 서버에 OR 조건으로 전달합니다. 전체/빈 선택은 장르 Query를 생략합니다.
새로고침은 현재 선택을 유지하며 이전 목록을 보존합니다. 실패하면 마지막 성공 목록을 복원하고
같은 장르 조건으로 page 1부터 재시도하거나 취소할 수 있습니다.
상세와 평점 Dialog에 실제 TMDB ID를 전달합니다.

## 실행

1. `.env.example`을 참고해 `.env`에 개인 `TMDB_ACCESS_TOKEN`을 입력합니다.
2. `flutter pub get` 후 `flutter run`을 실행합니다.
3. `flutter analyze`, `flutter test`로 검증합니다.

`.env`는 Git에서 제외합니다. 토큰 원문을 코드·기록·캡처에 남기지 않습니다.

## 제출 자료

실행 화면·영상·요청 로그·촬영 도구와 제출 정리는 로컬에 별도로 보관합니다.
이 PR에는 촬영 자료를 포함하지 않습니다.
성공 화면은 실제 TMDB 응답이며, 빈 목록·통신 실패·응답 지연·포스터 예외는
전용 테스트 실행에서 주입해 검증했습니다.

실기기 네트워크를 직접 끈 수동 촬영은 미수행이며, 오류 주입 검증으로 대체했습니다.

## 조사한 구현 근거

- RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
  짧은 목록에도 새로고침을 지원하도록 AlwaysScrollableScrollPhysics를 사용합니다.
  로딩 중에는 notificationPredicate와 ViewModel 가드로 중복 새로고침을 막습니다.
- TMDB Discover: https://developer.themoviedb.org/reference/discover-movie
  with_genres의 pipe 구분자는 OR 조건입니다.
