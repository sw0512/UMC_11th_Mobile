# 6주차 워크북 요구사항 검토

워크북 30~33쪽의 Guided / Required / Challenge 및 최종 체크리스트와 구현·검증 자료를 대조했습니다. 구현 누락은 발견하지 않았습니다.

| 요구사항 | 구현 및 검증 |
|---|---|
| 공용 MovieLogButton 및 기본·통신 중·비활성 | widgets/movielog_button.dart, week6_widgets_test |
| null / double.infinity / 고정 너비 | 공용 버튼 너비 테스트와 별도 촬영 화면 |
| 입력창 바깥 버튼, 8px 간격, 로딩 시 회색·인디케이터만 | sign_up_screen.dart, 촬영 화면 및 위젯 테스트 |
| 닉네임·이메일 직접 응답 파싱과 경로 인코딩 | MemberCheckService, CheckResult, week6_services_test |
| Form에 서버 오류 연결 | forceErrorText, Form.validate 후에도 중복 오류 유지 테스트 |
| 입력 변경 시 이전 결과 무효화 | SignUpViewModel, 지연 응답 무시 테스트 |
| 동일 중복 값 재입력 시 요청 없이 오류·비활성 복원 | 필드별 duplicated 저장 및 닉네임·이메일 테스트 |
| 정상 중복과 통신 실패 문구 구분 | duplicated / error 상태와 재시도 테스트 |
| 마이페이지 → 내 평점 및 뒤로가기, 하단 탭 숨김 | root Navigator의 /my/ratings, 위젯 이동 테스트 |
| 학습용 memberId 1 고정 및 공개 데이터 안내 | sampleMemberId 상수, MyRatingsScreen 안내, 호출 인자 테스트 |
| Loading / Empty / Error / Success | ViewModel 및 촬영 검증; 빈 배열·400·404·500·연결 실패 구분 |
| 점수·후기·등록일·영화 제목·포스터 | RatingWithMovie, 실제 v5 평점 3개와 TMDB 상세 결합 |
| comment:null 처리 | DTO와 null 후기 미표시, 실제 API 응답 및 테스트 |
| TMDB 실패 시 평점 유지, 중복 조회 캐시 | 404 placeholder, 일시적 실패 다음 load에서 재시도 테스트 |
| 화면 이탈·새 요청 이후 이전 결과 무시 | ViewModel 요청 버전 및 dispose 검증 |
| TMDB와 워크북 Client 분리 | 인증 없는 공용 워크북 Dio; 두 워크북 Service가 공유 |
| v5 범위 준수 | 새 Service는 GET만 사용; 회원가입 POST 및 평점 저장/수정/삭제 호출 없음 |

## 검증

- flutter analyze: 문제 없음
- flutter test: 38개 통과 (연결 실패 response:null 사례 포함)
- 실제 API·화면 검증: 통과, 중복/사용 가능과 공개 평점 3개 확인
- flutter build web --release: 성공
- 촬영 자료: 17장, 로컬 별도 보관 및 PR 제외

실제 API 성공·중복 응답은 서버를 호출해 검증했습니다. Empty·네트워크 실패·HTTP 오류·TMDB 정보 누락은 전용 테스트에서 주입했습니다. 캡처는 Flutter 테스트 렌더러이며, 실제 휴대폰의 키보드·회전·접근성 검증은 별도 수행하지 않았습니다.
