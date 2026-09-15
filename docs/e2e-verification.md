# Modern BBS E2E cross-service integration verification

Date: 2026-09-15 · Script: `scripts/e2e/e2e.sh` (repeatable)

## Environment

- Common `:4011` (PERSISTENCE_DRIVER=postgres, EVENT_DELIVERY_URL=community `/internal/events`)
- Community `:4012` (COMMUNITY_STORE=postgres)
- Commerce `:4013` (COMMERCE_PERSISTENCE=postgres, COMMON_BASE_URL=common)
- PostgreSQL per service via docker compose (host ports 5411/5412/5413); servers run from built `dist/`.

## Scenarios and results — 14 PASS / 0 FAIL

### S1 Service health
All three services boot in PG mode and answer `/health`.

### S2 Common lifecycle → projection event → HTTP delivery → Community inbox (real wiring)
1. `POST /members` on Common registers a member (ACTIVE, `emailVerified=false` — A-4 gating applies to login, not status).
2. Email verification case flow (create → 6-digit code → verify) sets `emailVerified=true`.
3. Common emits `MemberProjectionUpdated` in the same transaction as membership mutations (register + verification change → 2 events).
4. The persistent outbox publisher delivers them over HTTP to Community `POST /internal/events` (`x-source-service` header).
5. Community's persistent inbox consumer processes them; the member projection becomes `ACTIVE` in Community's `member_projections`.
6. Assertions: Common outbox rows all `published_at` set; Community inbox rows `PROCESSED`.

### S3 Commerce inbox receive contract + idempotency
1. The real `MemberProjectionUpdated` envelope (rebuilt from Common's `outbox_events` row, nulls stripped) is POSTed to Commerce `POST /internal/events` → `202`.
2. Commerce's inbox consumer applies it; `member_projections` shows `ACTIVE`.
3. Duplicate delivery of the same envelope is deduped (`(source, event_id)` unique) — exactly 1 inbox row.

## Gaps found during pre-flight and closed for this verification

| Gap | Resolution |
|---|---|
| Event contract mismatch: Common emitted only lifecycle events; consumers only handle `MemberProjectionUpdated` | Common now publishes projection events with membership mutations (`8bbe613`) |
| Commerce inbox: no HTTP receive endpoint, empty handler registry | `POST /internal/events` + projection handler (`c687965`) |
| Common ports had no HTTP client adapters in Community/Commerce | `COMMON_BASE_URL` adapters added (community `6c06d19`, commerce `c687965`) |
| Enum drift: consumers expected `PENDING_VERIFICATION`, Common canonical is `PENDING` | Aligned to `PENDING` (community `855b231`, commerce `bfbd161`) |

## Known limitations (documented, not blockers)

- **Single-target delivery**: Common's outbox delivers to one `EVENT_DELIVERY_URL`. S3 used envelope replay to exercise Commerce because Community was the live target. Real fan-out needs a broker or multi-target delivery — deployment concern, consumers stay idempotent either way.
- **Common HTTP adapters have no production trigger yet**: Community/Commerce expose `COMMON_BASE_URL` adapters, but no application use case calls them (points-as-payment awaits product decision #5). Their contracts are verified against stub Common servers in each repo's test suite; a live-call E2E becomes possible when a wired use case exists.
- **Unknown-event policies diverge**: Community dead-letters unknown event types; Commerce records a processed note. Operational expectation should be unified later.
- `x-source-service` is trusted without allowlist; add source allowlisting before real network exposure.

## Reproduce

```bash
./scripts/e2e/e2e.sh   # from the planning repo; requires docker + jq
```
