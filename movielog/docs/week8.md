# 8주차 학습 정리

## 인증과 인가

인증은 요청한 사용자가 누구인지 확인하는 과정이다. 로그인으로 accessToken을 발급받고, 보호 요청에 Bearer Header로 보낸다. 인가는 확인된 사용자가 해당 작업을 해도 되는지 검사하는 과정이다. 평점 수정·삭제의 소유권은 클라이언트의 memberId가 아니라 서버가 JWT를 검증해 결정한다.

로그인 입력 오류 AUTH401_1은 로그인 Form의 오류로만 표시한다. 보호 요청의 AUTH401_2/3/4는 토큰 없음·무효·만료이므로 현재 세션을 정리한다. RATING403_1은 권한 부족이므로 안내만 하고 로그아웃하지 않는다. 닉네임 중복 MEMBER409_1은 입력을 유지하고 필드 아래에 서버 메시지를 표시한다.

## 세션 상태와 화면 이동

- initializing: 보안 저장소와 서버 확인 중이며 Splash만 표시한다.
- signedOut: 로그인·회원가입 화면만 허용한다.
- authenticating: 로그인 중이며 입력과 중복 제출을 막는다.
- signedIn: 보호 화면에 접근한다.
- retryRequired: 네트워크 또는 저장소 확인 실패이며 Splash에서 재시도한다.

새 로그인은 로그인 API 성공 → 토큰 저장 → signedIn → MainScreen의 GET me 순서다. 앱 재실행은 토큰 읽기 → GET me 검증 성공 → signedIn 순서다. 토큰 문자열이 존재하는 것만으로 복원을 확정하지 않는다. Router의 redirect는 상태만 읽고, API 호출은 ViewModel에서 한다.

## 저장소와 요청 분리

JWT는 TokenStorage를 통해 flutter_secure_storage에만 저장한다. SharedPreferences에는 선택한 이메일만 저장하며 비밀번호는 저장하지 않는다. Android 백업을 비활성화했다. 로그아웃은 메모리의 사용자·현재 세션 평점과 저장된 토큰을 정리한다. 서버에서 이미 발급된 토큰이 폐기됐다고 보장하는 기능은 아니다.

TMDB Client는 TMDB 토큰만 사용한다. MovieLog 공개 Client는 로그인·중복 확인·공개 유저별 평점 조회에 사용한다. 보호 Client의 Interceptor는 지정한 HTTPS host와 /v7/members/me, /v7/ratings 경로에만 JWT를 붙인다. 보호 요청의 자동 리다이렉트도 차단한다.

## 늦은 응답과 계정 전환

세션이 바뀔 때 sessionVersion을 증가시킨다. 요청 시작 시 버전을 고정하고, Interceptor가 전송 직전과 토큰 읽기 후에 다시 검사한다. 이전 계정에서 시작한 요청은 새 계정의 토큰으로 전송하지 않는다. 응답을 적용할 때도 버전을 검사하므로 이전 GET me·PATCH 결과·401이 새 계정의 정보를 덮어쓰거나 로그아웃시키지 않는다. 동시에 여러 401이 와도 정리는 한 번만 진행한다. 진행 중인 토큰 저장이 있다면 기다린 뒤 삭제하고, 삭제가 실패하면 정리 재시도 전까지 새 로그인을 막는다.

## 평점 v6 → v7 변경

| 동작 | v6 | v7 |
| --- | --- | --- |
| 등록 | /v6/members/{memberId}/ratings | /v7/ratings |
| 수정·삭제 | memberId와 ratingId path | /v7/ratings/{ratingId} |
| 사용자 식별 | memberId path | Bearer JWT |
| 등록 성공 | 201, scalar/null result | 201, Rating 객체 result |
| 수정 성공 | 200, null result | 200, Rating 객체 result |
| 삭제 성공 | 204, body 없음 | 200, wrapper/result null |

PATCH는 score와 comment를 항상 함께 보낸다. 기존 코멘트를 초기 입력값으로 채우고, 빈 입력은 null로 전달해 지운다. 등록·수정 응답의 Rating을 현재 세션 카드에 반영한다. movieId는 실제 선택한 TMDB DTO의 id이며 제목·포스터는 그 ID로 결합한다. 영화 정보 조회에 실패해도 평점은 유지하고 placeholder를 표시한다.

## API 한계

로그인·GET me 응답에는 memberId가 없고 토큰 기반 전체 내 평점 GET도 없다. JWT claim을 추정하거나 임의 ID를 넣지 않는다. 현재 로그인에서 새로 등록한 평점만 메모리에 보관해 수정·삭제한다. 로그아웃·계정 전환·앱 종료 뒤에는 목록을 비운다. 기존 전체 평점 복원은 지원 완료로 표시하지 않는다.

## 챌린지

이메일만 기억하기, 마이페이지 전체 로딩·실패·재시도, 서버 가입일 표시, 프로필 미저장 변경 시 나가기 확인을 구현했다. 프로필 이메일은 읽기 전용이며 닉네임만 수정한다.

9주차는 이 인증 경계 위에 즐겨찾기·검색·페이지네이션을 연결하고, 10주차는 Android 릴리스·서명·Smoke Test로 이어진다. 이번 작업 범위는 8주차다.
