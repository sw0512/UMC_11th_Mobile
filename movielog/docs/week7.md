# 7주차: 회원가입과 평점 CRUD

## 실행

기존 `.env`의 TMDB Read Access Token 설정 후 `flutter pub get`, `flutter run`으로 실행합니다. 회원가입의 닉네임은 2~12자, 비밀번호는 8자 이상이며 대문자·소문자·숫자·지정 특수문자를 포함해야 합니다.

회원가입 성공 응답의 memberId를 LearningMemberSession에 보관합니다. 이 값은 메모리에만 유지되는 학습용 식별자이며 인증 토큰이 아닙니다. 앱을 다시 실행하면 새로 회원가입해야 합니다. 고정 memberId 1로 쓰기 요청을 보내지 않습니다.

## 구현 흐름

- SignUpService: v6 중복 확인 직접 객체, 회원가입 CommonResponse<SignUpResult> 처리
- SignUpViewModel: 입력 무효화·중복 값 캐시 유지, 최종 409와 비밀번호 400 구분, 중복 제출 차단
- MovieDetailLoader: TMDB DTO extra 전달 또는 URL ID로 한 번 조회
- MovieDetailViewModel: 세션 회원과 실제 TMDB ID로 평점 등록
- RatingDialog: 정수 별점 1~5, 코멘트 최대 500자, 저장 중 입력·취소·뒤로가기 차단, 실패 시 입력 보존
- MyRatingsViewModel: 본인 학습용 회원 조회·수정·삭제, 저장과 GET 재조회 상태 분리
- 단일 삭제: 확인창에서 요청이 끝날 때까지 로딩·이탈 차단
- 다중 삭제: 선택 복사본을 순회, 확인창을 닫고 화면 오버레이 표시, 일부 실패한 선택만 유지

등록 성공은 상세 화면 Snackbar로 안내하며 조회·수정·삭제는 마이페이지에서 진행합니다. 평점 기록과 TMDB 제목·포스터는 movieId로 결합합니다.

## API 계약

- 회원가입 POST: 201 + wrapper, result.memberId 필수
- 중복 확인 GET: 200 + 직접 객체
- 평점 GET: 200 + 직접 배열
- 평점 POST: 201 + wrapper, result가 숫자 또는 null이어도 강제 캐스팅하지 않음
- 평점 PATCH: 200 + wrapper, score 및 comment를 명시적으로 전달 (빈 comment는 null로 삭제)
- 평점 DELETE: 204, 본문 파싱 없음
- 오류: COMMON400 / COMMON403 / COMMON404 / COMMON409의 서버 message 유지, 403·404는 목록 재조회

## 검증 및 범위

60개 자동 테스트와 실제 본인 테스트 계정의 API·화면 검증을 완료했습니다. 세부 결과와 재현 조건은 로컬 제출 자료에 보관하고, 촬영 도구·자료·테스트 계정 정보·개인 .env는 PR에 포함하지 않습니다.

실제 휴대폰의 키보드·회전·접근성은 별도 검증하지 않았습니다. 403과 일부 네트워크 오류는 다른 회원의 데이터를 건드리지 않도록 주입해 검증했습니다.

## 참고

- 공식 v6 명세: https://workbook.devnoco.com/docs/v6-json
- PopScope: https://api.flutter.dev/flutter/widgets/PopScope-class.html
- showDialog: https://api.flutter.dev/flutter/material/showDialog.html
