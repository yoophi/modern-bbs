# modern-bbs 후속 작업 — 백엔드 계약 갭 해소 및 인프라 정리

작성일: 2026-09-17 (SPA 클라이언트 목표 완료 후 후속 단계)
오케스트레이션: SPA task.md와 동일 프로토콜 (Unit별 새 Herdr OpenCode tab, glm-5.3, 구현 → 검증 → 리뷰 1회 → 피드백 1회 반영 → review-fix 1 커밋 → push)

## 배경

modern-bbs-spa-client 최종 감사(docs/reviews/final-audit-opencode-glm-review.md)에서 발견된 백엔드 추적 항목 4건 + 저장소 인프라 문제. 이 단계에서는 modern-bbs-commerce 저장소를 수정한다(SPA 목표의 "백엔드 수정 금지" 제약은 이 단계에는 적용되지 않는다).

## Unit B0 — 저장소 인프라 정리 (오케스트레이터 직접, 커밋 없음)

- [x] B0-1 루트 modern-bbs remote 오타 수정: `gitbhub.com` → `github.com` + push
- [x] B0-2 modern-bbs-common, modern-bbs-community: gh private repo 생성 + origin 등록 + push (clean 상태 확인 후)
- [x] B0-3 modern-bbs-commerce: dirty 변경은 Unit B1에서 완성 후 push (B1까지 remote 생성만)
- [x] B0-4 followup-task.md 커밋·push (루트)

## Unit B1 — commerce 옵션 active 필드 완성 (중단 작업 인계)

- [x] B1-1 기존 dirty 변경 분석: productOptionSchema `active` 필드, domain/models·stock-policy·service·postgres repositories·migration 0024(옵션 active 칼럼) — 누락 부분 파악
- [x] B1-2 완성: memory 저장소 adapter 반영, 옵션 비활성화 시 판매 제외 로직(assertProductSelection 통과), openapi.json 계약 갱신(active 필드 + 비활성 옵션 응답 규칙), route-parity/conformance 테스트 갱신
- [x] B1-3 백엔드 테스트 통과(npm run typecheck && test, memory+PG 조건부) + 커밋 `feat(options): option active flag with sold-out interplay`
- [x] B1-4 완료 프로토콜(리뷰 1회 + review-fix 1 + push)

## Unit B2 — commerce 계약 문서 정합

- [x] B2-1 openapi.json `/admin/points/grants` requestBody required에 `idempotencyKey` 추가(서버 zod와 일치), conformance 테스트 통과
- [x] B2-2 계약 전수 대조: 서버 zod 스키마 ↔ openapi requestBody/required 불일치 다른 건 전량 조사·수정
- [x] B2-3 커밋 `fix(contracts): align openapi required fields with server validation` + 완료 프로토콜

## Unit B3 — 관리자 상품 목록 op

- [x] B3-1 GET /admin/products 구현: status 필터(DRAFT|SUSPENDED|DISCONTINUED|PUBLISHED 전체), keyword/sku 검색, 페이지네이션 — 현재 searchProducts는 PUBLISHED만 반환해 비공개 상품이 관리 목록에 영구 누락
- [x] B3-2 openapi + conformance/route-parity + 서비스 테스트
- [x] B3-3 커밋 `feat(admin): product listing across all statuses` + 완료 프로토콜

## Unit B4 — 대량 목록 페이지네이션 계약

- [x] B4-1 page/limit 파라미터 추가: admin points ledger, order events, order archives, wishlist reports (응답에 page/limit/total 추가 — 기존 소비자 호환 확인)
- [x] B4-2 openapi + 테스트 + 커밋 `feat(contracts): pagination for large administrative listings` + 완료 프로토콜

## Unit B5 — 옵션 참조 오염 조사

- [x] B5-1 재현 시도: 09-17 스모크에서 관찰된 "옵션/상품 참조 오염(product not found)" — memory 저장소(commerce-memory-repositories)의 저장·조회 경로 분석, 특히 카트 라인 추가·부분취소·BANK 제출 409 경로 후 옵션 소실 시나리오 재현
- [x] B5-2 재현 시 수정 + 회귀 테스트, 미재현 시 분석 문서화(docs/known-issues.md)
- [x] B5-3 커밋(`fix(memory): ...` 또는 `docs: ...`) + 완료 프로토콜

## Unit B6 — SPA 동기화 (modern-bbs-spa-client)

- [x] B6-1 B1 active 필드·B2 계약 정합·B3 관리자 상품 목록·B4 페이지네이션 반영: types/endpoints 갱신, 관리자 상품 목록을 /admin/products로 전환, 대량 목록 페이지네이션 UI, 상품 상세 비활성 옵션 표시 규칙
- [x] B6-2 typecheck/test/build + integration-smoke.sh 갱신(신규 op 커버) + 커밋 + 완료 프로토콜

## 의존성

```
B0 → B1 → B2 → B3 → B4 → B6
      B1 → B5 (병행 가능)
```

## 제외/원칙

- 백엔드 각 Unit은 해당 저장소 관례를 따른다(hexagonal, route-parity, conformance, canonical errors)
- SPA(B6)는 B3·B4 완료 후에만 시작
- legacy 원칙: docs/migration-coverage-report.md에 진행 상황 기록 갱신
