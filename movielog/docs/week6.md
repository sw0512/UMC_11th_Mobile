# 6주차: v5 중복 확인과 학습용 평점 조회

## 실행

기존 TMDB `.env` 설정 후 `flutter pub get`, `flutter run`으로 실행합니다.
워크북 API 주소는 `https://workbook.devnoco.com`이며 인증 헤더 없이 공개 v5 GET 경로만 사용합니다. TMDB 전용 Client와 분리했고 MemberCheckService와 RatingApiService는 공용 Dio 인스턴스를 공유합니다.

## 확인 경로

- 시작하기 → 회원가입 → 닉네임·이메일 형식 입력 → 각각 중복 확인
- available:false이면 Form 오류와 확인 버튼 비활성화
- 다른 문자열을 입력하면 idle, 직전 중복 값을 다시 입력하면 요청 없이 duplicated 복원
- 두 중복 확인, 로컬 형식 검증, 약관 동의 완료 후 홈 이동 (회원가입 POST 없음)
- 마이페이지 → 내가 등록한 평점 → 회원 1번 공개 평점
- 뒤로가기 시 프로필·하단 탭 복원. 자식 평점 화면에는 하단 탭 없음

## 구조

- MovieLogButton: 기본·로딩·비활성 상태와 내용/전체/고정 너비
- SignUpViewModel: 닉네임·이메일별 상태, 요청 버전, 마지막 중복 값
- MemberCheckService: 경로 인코딩 후 CheckResult 직접 파싱
- RatingApiService: v5 직접 배열 파싱, 400/404/일반 실패 메시지 구분
- MyRatingsViewModel: 학습용 memberId=1, 네 가지 상태, 영화 정보 결합·캐시
- TmdbMovieService: 영화 상세 조회, 404만 null로 처리
- RatingWithMovie: TMDB 정보가 없어도 평점 기록 유지

38개 자동 테스트와 별도의 실제 API 촬영 검증을 통과했습니다. 촬영 도구·자료와 제출 정리는 로컬에 별도로 보관하며 PR에는 포함하지 않습니다.

## 참고

- 공식 v5 명세: https://workbook.devnoco.com/docs/v5-json
- Flutter TextFormField: https://api.flutter.dev/flutter/material/TextFormField-class.html
- Flutter Form validation: https://docs.flutter.dev/cookbook/forms/validation
