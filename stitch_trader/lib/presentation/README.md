# presentation

UI: 페이지, 위젯, 테마, 상태(Provider/Riverpod/Bloc 등 — Phase 3 확정).

**현재(P0~2):** 기존 코드는 아직 `lib/screens/`, `lib/theme/` 에 있습니다.  
**Phase 3:** 이 디렉터리로 이전 후 레거시 경로를 제거합니다.

`application`의 유스케이스만 호출하고, `infrastructure` 구현체를 직접 참조하지 않습니다.
