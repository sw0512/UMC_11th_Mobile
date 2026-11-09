# 7주차 요구사항 검토

워크북의 진행 원칙, Guided A/B, Required, Challenge 및 최종 체크리스트를 코드·테스트·실제 API 증거와 대조했습니다.

| 요구사항 | 구현 및 검증 근거 |
|---|---|
| TMDB/MovieLog Client 분리 | 기존 전용 Client 유지, 워크북에 TMDB 인증 헤더를 보내지 않음 |
| 본인이 생성한 회원 식별 | 회원가입 result.memberId → LearningMemberSession → 상세·평점 Route |
| DTO extra와 직접 링크 | TmdbMovieCard의 실제 DTO 전달, MovieDetailLoader의 일회성 TMDB 상세 조회 |
| 입력 모델과 응답 모델 구분 | CreateMemberRequest / CreateRatingRequest / SignUpResult / RatingDto |
| 닉네임·이메일 확인 무효화 | 기존 요청 버전·중복 값 캐시 유지, 제출 중 변경 차단 |
| 실제 회원가입 POST와 결과 ID | SignUpService의 201·result 검증, 세션 저장 후 /movies 이동 |
| 회원가입 오류 목적지 | 비밀번호를 명시한 400만 필드 오류, 그 외 400·409는 Snackbar |
| 가입 요청 중 중복·이탈 차단 | ViewModel guard, AbsorbPointer, PopScope, AppBar 뒤로가기 guard |
| 별점 정수 1~5 | 정수 RatingBar와 validateServerScore, 비정수·범위·NaN·Infinity 거부 테스트 |
| 코멘트 입력·최대 500자 | RatingDialog의 수명 중 한 번 만든 Controller와 dispose, 선택 입력 |
| 수정 초기값 및 null 처리 | initialScore/initialComment, 빈 칸은 null, PATCH comment 명시 |
| 저장 중 Dialog 닫힘 차단 | barrierDismissible:false + PopScope + 버튼·입력 비활성화 |
| 저장 실패 입력 보존 | Dialog가 API 오류를 표시하고 로딩을 해제, 409 및 실패 테스트 |
| 등록 위치·결과 안내 | 영화 상세에서 등록, 성공 Snackbar; 조회·수정·삭제는 마이페이지 |
| 본인 목록에서만 수정·삭제 | 세션 ID의 GET 결과만 표시, ratingId 소유 목록 guard |
| 상태/영화 정보 연결 | 네 가지 조회 상태와 RatingWithMovie 캐시/placeholder 유지 |
| 직접 객체·배열·wrapper·204 | API별 응답 계약을 분리하고 DELETE 본문을 읽지 않음 |
| 저장 성공과 GET 실패 분리 | write 성공 후 refreshWarning, GET 전용 재시도, 쓰기 횟수 불변 테스트 |
| 400/403/404/409 구분 | ApiFailure의 status/code/message, 403·404 재조회 테스트 |
| 단일 삭제 취소·확인 | 취소 시 DELETE 없음, 저장 중 확인 Dialog 유지, 마지막 삭제 후 Empty |
| 다중 선택 UI | 편집/취소, 선택 개수, Checkbox, 0개 선택 시 하단 버튼 비활성 |
| 다중 삭제 동작 | 확인창 즉시 pop, 화면 로딩 오버레이·PopScope·입력 차단 |
| 부분 실패 | 성공 항목 제거, 실패 선택 유지, 결과 Snackbar와 실패 항목만 재시도 |
| 늦은 응답·dispose | ViewModel 버전/폐기 guard와 지연 응답 테스트 |
| 비밀번호 보관 금지 | 로그/SharedPreferences에 저장하지 않음, 테스트 계정 비밀번호도 메모리에서만 사용 |

## 확인 결과

- 정적 분석 및 60개 자동 테스트 통과
- 실제 API의 새 회원 가입 및 그 회원 경로에서 CRUD 확인
- 201/200/204와 실제 중복 409 처리 확인
- 403·일부 네트워크 실패 및 부분 실패는 전용 검증에서 주입 (다른 회원 데이터 조작 없음)
- 촬영은 Flutter 테스트 렌더러; 실기기 검증과 구분

구현 누락은 발견하지 않았습니다. API 성공/실패 계약과 사용자 복구 동작을 검증했으며, 실기기 키보드·회전·접근성 동작은 별도 미검증입니다.
