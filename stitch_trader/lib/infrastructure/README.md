# infrastructure

외부 세계와의 어댑터: HTTP, DB, 키움 SDK, 로컬 저장소 등.

- `domain`의 리포지토리 **구현체**만 둡니다.
- DTO·직렬화는 가능하면 이 레이어(또는 하위 `api/`·`database/`)에 둡니다.

- **Phase 4:** `api/` HTTP 클라이언트·매퍼, `remote/` REST 구현 — 계약은 `docs/PHASE4_HTTP_CONTRACT.md`.
- Phase 3까지는 `fake/` 로 UI 검증 가능.
