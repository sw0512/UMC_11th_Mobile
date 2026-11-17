# 8주차 요구사항 검토

명세: Notion 8주차 JWT 토큰 기반 로그인 및 세션 복원. 9주차 즐겨찾기·검색·페이지네이션, 10주차 릴리스 요구사항도 확인했으며 이 PR은 8주차만 구현합니다.

| 범위 | 구현·검증 |
| --- | --- |
| 로그인·안전한 저장 | 공개 Client 로그인, secure storage write/read/delete, 비밀번호 미보관 |
| 복원 | 저장된 토큰을 GET me로 검증한 뒤 signedIn, 네트워크·저장소 실패 재시도 |
| Router | 앱 수명 중 한 번 생성, refreshListenable·redirect로 보호 화면 통제 |
| Client 분리 | 공개 / 보호 / TMDB 분리, 보호 HTTPS host·path만 Bearer, 자동 redirect 차단 |
| 만료·계정 전환 | AUTH401_1은 Form, 보호 AUTH401_2/3/4는 정리, 403은 유지 |
| 경합 | 동시 만료 정리 한 번, 저장 완료 뒤 삭제, 정리 실패 시 새 로그인 차단 |
| 늦은 요청·응답 | 요청 시작 버전 고정과 전송 직전 재검사, 이전 세션 응답·401 무시 |
| 내 정보 | MainScreen이 GET me 한 번, 로딩·실패·재시도, 닉네임·이메일·가입일 표시 |
| 프로필 수정 | 읽기 전용 이메일, 닉네임 2~12자·변경 없음 생략·중복 입력 유지·성공 반영 |
| 평점 v7 | memberId 제거, POST 201/PATCH 200 Rating 객체, DELETE 200 wrapper/null |
| 코멘트 | 수정 초기값 채우기, score/comment 함께 전송, 빈 입력 null |
| 현재 세션 평점 | 서버 응답 Rating 보관, TMDB ID 결합·placeholder, 로그아웃 시 제거 |
| API 한계 | 토큰 기반 전체 목록 GET 없음, memberId/JWT claim 추정 없음, 재시작 전체 복원 미지원 명시 |
| Challenge | 이메일만 기억하기, 전체 프로필 로딩·재시도, 가입일, 변경 이탈 확인 |

## 검증 결과

- 자동 테스트 64개 통과, flutter analyze 이상 없음
- 웹 release 컴파일 성공, Android debug 빌드 성공
- Pixel 9 Android 16 에뮬레이터 실제 secure storage write → 새 인스턴스 read → delete 검증
- 실제 서버의 로그인 실패/성공, GET me, 닉네임 409/수정 성공, 평점 등록/수정/삭제, 무효 토큰 401, 보호 화면 차단 확인
- 일반 앱을 재설치(데이터 유지)하고 프로세스를 완전히 다시 켜도 GET me를 거쳐 본인 프로필 복원 확인
- 직접 로그아웃 후 프로세스 재시작에서 로그인 화면 유지 확인
- 테스트 앱 패키지는 opt-in Gradle property week8Probe=true로 별도 suffix를 사용해 기존 앱 데이터를 분리

수동 native 검증 명령은 ORG_GRADLE_PROJECT_week8Probe=true를 지정한 flutter drive --keep-app-running --driver=test_driver/week8_driver.dart --target=integration_test/week8_live_test.dart입니다. 이 검증은 별도 본인 테스트 계정을 생성하며 비밀번호와 JWT를 결과 파일에 내보내지 않습니다. 증거 파일은 로컬 제출 폴더/Notion에 보관하고 Git에 올리지 않습니다.

## 한계

- iOS secure storage와 재설치 Keychain/최초 설치 flag는 검증하지 않았습니다.
- 자동 테스트의 403·네트워크 실패·저장소 실패·동시 401·늦은 응답은 주입 시나리오입니다. 타 회원 평점 변경으로 403을 재현하지 않았습니다.
- 재시작 뒤 전체 내 평점 목록 복원은 서버 계약상 제공하지 않습니다.
- Android 릴리스 서명·배포는 10주차 범위입니다.
