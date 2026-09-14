# Modern BBS milestone review log

Date: 2026-09-15

## Milestone 1 — authority documents and backlog

- Repo: `/Users/yoophi/project/modern-bbs`
- Commit: `2a7d9a2 docs: capture modern bbs research and backlog`
- Artifacts:
  - `docs/modern-bbs-implementation-backlog.md`
  - research documents under `docs/*.md`
- Review result:
  - Confirmed backlog maps Logseq/repo/legacy sources into Common, Community and Commerce ownership.
  - Explicitly documented exclusions and unresolved product decisions.
- Verification:
  - Source documents re-read.
  - Legacy schema/table inventory extracted from `install/gnuboard5.sql` and `install/gnuboard5shop.sql`.

## Milestone 2 — independent repo bootstrap

### Common

- Repo: `/Users/yoophi/project/modern-bbs-common`
- Commit: `ae7637c chore: bootstrap service scaffold`
- Review: `docs/reviews/0001-scaffold-review.md`
- Review fix applied:
  - Split `tsconfig.json` and `tsconfig.build.json` after typecheck failed with rootDir/test/config inclusion.
  - Added architecture documentation and local migration smoke instructions.
- Verification:
  - `npm run db:generate`
  - `npm run typecheck`
  - `npm test`
  - `npm run build`
  - `npm run lint`
  - `npm run db:migrate` against dockerized PostgreSQL

### Community

- Repo: `/Users/yoophi/project/modern-bbs-community`
- Commit: `45a101d chore: bootstrap service scaffold`
- Review: `docs/reviews/0001-scaffold-review.md`
- Review fix applied: same scaffold fixes as Common.
- Verification: same scaffold command set as Common.

### Commerce

- Repo: `/Users/yoophi/project/modern-bbs-commerce`
- Commit: `11496d9 chore: bootstrap service scaffold`
- Review: `docs/reviews/0001-scaffold-review.md`
- Review fix applied: same scaffold fixes as Common.
- Verification: same scaffold command set as Common.

## Milestone 3 — Common service core

- Repo: `/Users/yoophi/project/modern-bbs-common`
- Commit: `7bbb85b feat: add common service core contracts`
- Review: `docs/reviews/0002-common-core-review.md`
- Review fixes applied:
  - Replaced unsafe Hono status `as never` cast with `ContentfulStatusCode`.
  - Added conformance-style points tests for idempotency, reservation, commit/release and reversal.
- Verification:
  - `npm run typecheck`
  - `npm test` — 3 files / 8 tests at review time
  - `npm run build`
  - `npm run lint`
  - `npm run db:generate`
  - `npm run db:migrate` against dockerized PostgreSQL

## Milestone 4 — Community service core

- Repo: `/Users/yoophi/project/modern-bbs-community`
- Commit: `ec7a92f feat: add community core domain api`
- Review: `docs/reviews/0002-community-core-review.md`
- Review fixes applied:
  - Added local Common ports only; no Common/provider implementation imports.
  - Added typed `BoardPolicy` rather than generic settings.
  - Attachment handling uses `AssetId` references instead of file paths/media SDK objects.
- Verification:
  - `npm run typecheck`
  - `npm test` — 2 files / 5 tests at review time
  - `npm run build`
  - `npm run lint`
  - `npm run db:generate`
  - `npm run db:migrate` against dockerized PostgreSQL

## Milestone 5 — Commerce service core

- Repo: `/Users/yoophi/project/modern-bbs-commerce`
- Commit: `0c04672 feat: add commerce core workflow api`
- Review: `docs/reviews/0002-commerce-core-review.md`
- Review fixes applied:
  - Allowed cart line changes after explicit guest cart claim (`ACTIVE` or `CLAIMED`).
  - Kept Common integration as local ports only.
  - Order stores customer and line snapshots.
- Verification:
  - `npm run typecheck`
  - `npm test` — 2 files / 4 tests at review time
  - `npm run build`
  - `npm run lint`
  - `npm run db:generate`
  - `npm run db:migrate` against dockerized PostgreSQL

## Milestone 6 — cross-service contracts and reliability guards

### Common

- Repo: `/Users/yoophi/project/modern-bbs-common`
- Commit: `9f34c13 feat: add cross-service contract guards`
- Review: `docs/reviews/0003-cross-service-contract-review.md`
- Verification: `npm run typecheck`, `npm test`, `npm run build`, `npm run lint`, `npm run db:generate`

### Community

- Repo: `/Users/yoophi/project/modern-bbs-community`
- Commit: `d54b35d feat: add cross-service contract guards`
- Review: `docs/reviews/0003-cross-service-contract-review.md`
- Verification: `npm run typecheck`, `npm test`, `npm run build`, `npm run lint`, `npm run db:generate`

### Commerce

- Repo: `/Users/yoophi/project/modern-bbs-commerce`
- Commit: `b174940 feat: add cross-service contract guards`
- Review: `docs/reviews/0003-cross-service-contract-review.md`
- Verification: `npm run typecheck`, `npm test`, `npm run build`, `npm run lint`, `npm run db:generate`

Review fixes applied across all three:

- Rewrote contract docs after shell heredoc expansion corrupted backtick sections.
- Added executable contract guard tests and idempotent inbox handler.

## Current known follow-ups

- PostgreSQL repositories are still mostly schema/migration level; application services are in-memory behavioural slices.
- OpenAPI YAML generation is deferred; `docs/api.md`, `docs/contracts.md`, and `/capabilities` are the current equivalent contract artifacts.
- Persistent outbox publisher/inbox storage workers are not production-grade yet; current `IdempotentInbox` defines semantics and tests.
