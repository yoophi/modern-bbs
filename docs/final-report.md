# Modern BBS final verification report

Date: 2026-09-15 (updated after task-12; supersedes the task-8 baseline report)

## Repositories

| Service | Path | Milestone commits (task-9 → task-12) |
|---|---|---|
| Common | `/Users/yoophi/project/modern-bbs-common` | `a7729b1`, `888c7d4`, `2f2eb72`, `e9e74fb` |
| Community | `/Users/yoophi/project/modern-bbs-community` | `49ff9bb`, `7eb8b44`, `384941a`, `92bb4b7` |
| Commerce | `/Users/yoophi/project/modern-bbs-commerce` | `f25703f`, `8235c1b`, `79b43c2`, `29653fb`, `ced361d`, `9f22da3` |
| Planning/research | `/Users/yoophi/project/modern-bbs` | this report |

## Final verification results (coordinator-run, 2026-09-15)

All three repos, on their task-12 HEADs:

| Gate | Common | Community | Commerce |
|---|---|---|---|
| `npm run build` / `typecheck` | pass | pass | pass |
| `npm test` with DB up | 19 files / 99 tests pass | 11 files / 52 tests pass | 11 files / 71 pass + 1 skip |
| `npm test` with DB down | 49 pass + 50 skip (green) | 35 pass + 17 skip (green) | 49 pass + 23 skip (green) |
| `npm run db:migrate` (re-run) | idempotent | idempotent | idempotent |
| `npm run db:generate` | no diff | no diff | no diff |

PG integration tests skip cleanly without Docker and run fully with `npm run db:up` (host ports 5411/5412/5413). Contract artifacts (`docs/contracts/openapi.json` + JSON Schemas) are kept in route parity with each Hono app by contract tests.

## What tasks 9–12 added over the task-8 baseline

1. **task-9 PostgreSQL repository wiring** — application services run on Drizzle/pg repositories behind unchanged ports; transactional use cases (points reserve/commit/release, post/comment writes, checkout/order) commit aggregate changes + outbox rows in a single transaction; `.env`-driven composition (memory/postgres).
2. **task-10 Persistent outbox/inbox workers** — seq-ordered outbox publisher (claim-safe, retry/backoff, dead-letter), persistent `inbox_events` consumer with `(source, event_id)` dedupe and crash resume; commerce hardened API idempotency with payload fingerprints (`IDEMPOTENCY_CONFLICT`).
3. **task-11 Contract artifacts** — OpenAPI 3.1 documents + event envelope / canonical error / idempotency JSON Schemas per repo, validated by structural, route-parity and conformance tests.
4. **task-12 Legacy depth expansion** — see mapping below; remaining backlog explicitly classified in each repo's `docs/legacy-gap-closure.md`.

## Implemented legacy feature mapping (final)

### Common

| Legacy area | Implemented |
|---|---|
| Login/session (`g5_member_auto_login`) | login/logout, session list/revoke, refresh sessions; local credential adapter + PG/in-memory |
| Social profiles (`g5_member_social_profiles`) | external identity link/list/unlink seam (port + adapters; no real OIDC) |
| Verification (`g5_cert_history`) | email/phone verification cases: create (code, TTL), list, verify with attempt limit; `MemberVerificationChanged` |
| Member profile | register, facts, status, profile update (displayName/contact/segments) with version bump + lifecycle events |
| Admin member management | member search/list with status/segment/loginId/displayName filters + pagination |
| Password recovery | request (token + `PasswordRecoveryRequested` in same tx) / reset (`PasswordResetCompleted`); no real mail |
| Grants (`g5_auth`, `mb_level`) | platform grants, decisions, batches; legacy mb_level→role mapping adapter seam |
| Points (`g5_point`) | balance, grant, reserve/commit/release/reverse, transaction paging, reservation expiry sweep, idempotency outcome lookup |

### Community

| Legacy area | Implemented |
|---|---|
| Groups (`g5_group`, `g5_group_member`) | group create/list/detail, membership upsert/remove (group admin or operator), board group assignment |
| Boards (`g5_board`) | typed `BoardPolicy` create/patch, copy, soft delete, capability-enriched list/detail |
| Posts | create/list/detail/search (multi-board via `boardIds`), revise, soft delete, notices, categories, reply threading (`parentPostId`), secret posts, attachment `AssetId` refs, view counts |
| Autosave (`g5_autosave`) | per-member draft save/fetch |
| Link clicks | external link click recording per (post, url) |
| Comments | create/reply/list, revise, soft delete; author snapshots |
| Reactions (`g5_board_good`) | one UP/DOWN per member/post with duplicate prevention |
| Scrap (`g5_scrap`) | add/list/remove with (member, post) uniqueness and read-permission gate |
| Feed (`g5_board_new`) | unified latest posts+comments feed with permission filtering |
| Moderation | case open, operator actions, bulk delete/move in one transaction with summary events |

### Commerce

| Legacy area | Implemented |
|---|---|
| Categories (`g5_shop_category`) | admin category tree create/list, product assignment, per-category browsing |
| Products/options (`g5_shop_item*`) | create/list/detail, options/variants with per-option price/stock, related products |
| Coupons (`g5_shop_coupon`) | coupon create, quote application with policy version/expiry |
| Cart (`g5_shop_cart`) | guest/member cart, server-priced validated lines, line quantity change/remove/select, guest claim |
| Wishlist (`g5_shop_wish`) | add + wishlist stats in reporting |
| Orders (`g5_shop_order*`) | idempotent submit with snapshots, state transitions (paid→preparing→shipped→completed), member list/detail, cancellation, partial cancellation with restock, return request/approval with return receipts |
| Addresses (`g5_shop_order_address`) | address book CRUD with single default, member isolation |
| Payment | stub adapter behind port: authorize/capture/void/refund + status; duplicate-safe command idempotency |
| Inventory | adjustments, checkout commit/restore, reservation TTL expiry sweep, back-in-stock subscriptions (outbox event only) |
| Fulfillment (`g5_shop_sendcost` scope partial) | shipment create/dispatch with tracking info, return receipt recording |
| Reviews/Q&A (`g5_shop_item_use`, `g5_shop_item_qa`) | review write/list with admin approval, inquiry write + answer with secret access policy |
| Reporting | sales by period, sales rank (net of cancel/return), wishlist stats |

## Exclusions honored

- No React/Admin SPA, no custom templates/skins.
- No real PG (payment gateway) integration — stub adapters + contracts only.
- No real SMS/email delivery — outbox events and stubs only.
- No legacy PHP compatibility layer.
- No RSS channel adapter, no real HTML sanitizer (policy seam only), no banner/event display tracking, no Excel bulk import tooling.

## Product decisions still open (tracked in each repo's `docs/legacy-gap-closure.md`)

1. Guest checkout retention and guest-cart merge UX (backlog #1).
2. Suspended-member permissions over existing posts/orders (backlog #2).
3. Anonymization/retention scope for author names, snapshots, reviews, Q&A, logs; member export privacy scope (backlog #3).
4. Community read/download point charging (backlog #4).
5. Point earning timing (backlog #5).
6. Partial cancellation/return allocation order for coupon, shipping, tax, points, refunds (backlog #6).
7. Coupon zone / member-targeted / point-purchased coupons; personalpay policy (backlog #2-related).
8. Membership projection maximum staleness (backlog #9); quote validity rules (backlog #10).
9. Adjacent Community modules: memo, poll, 1:1 inquiry (backlog #12).
10. Point grant lot expiry policy (single-balance model implemented; lot-based decision pending).

## Remaining engineering risks

- Admin/internal endpoints are unauthenticated by scaffold policy; must be gated before any real exposure.
- Verification codes/tokens/session ids are stored/returned in plaintext; hashing + delivery channels need a security milestone.
- Outbox claim fencing is status-based; at-least-once duplicates are possible under extreme timing (consumers must stay idempotent).
- Commerce: ORDERED-cart resubmission is not blocked (pre-existing since task-9, recorded); `back_in_stock_subscriptions` lacks a unique index for nullable option (rare duplicate race); partial cancel/return restores stock but computes no refund amounts (awaits decision #6).
- Community: no cursor pagination on feed/scrap/search yet (limit caps only); group membership does not affect board visibility (documented design decision).
- Common: legacy authz seam and sweep `now` override are in-memory/test-facing only.
- Dependency vulnerabilities reported by `npm install` during scaffolding still require hardening before release.

## Operating notes

Per service: `npm install`, `npm run db:up`, `npm run db:migrate`, `npm test`, `npm run build`, `npm run dev`. Host PG ports: common 5411, community 5412, commerce 5413. `PERSISTENCE_DRIVER`/store env (see each repo's README) selects postgres vs in-memory. Docs per repo: `docs/api.md`, `docs/contracts/`, `docs/legacy-gap-closure.md`, `docs/reviews/0001–0007`.

## Conclusion

All 13 goal tasks are complete. Three independent services build, test (unit + PG integration), and migrate cleanly; persistence, persistent messaging, contract artifacts, and legacy feature depth are in place; unresolved items are explicitly classified as product-undecided or excluded rather than silently dropped.

## Addendum: task-13 — legacy gap audit and High-priority closure (2026-09-15)

A two-pass, read-only audit against the gnuboard5 source (committed per repo as `docs/legacy-gap-audit.md`) surfaced items beyond the task-12 classification. All High-priority findings were then closed in per-unit implement→review→reflect→commit loops (reviews `docs/reviews/0008`–`0014`):

- **Common** — session credential hashing/device metadata/GC/admin remember-me ban; status-change session invalidation; consent model with audit log; email certification gating with policy TTL; email validation chain. 132 tests.
- **Community** — deleted-post comment visibility + self-reaction block (defects); three-tier admin delegation (board admin, expanded group admin); legacy-compatible pagination; category filter; outbox retry-visibility clock-skew fix. 68 tests.
- **Commerce** — supplementary option kind with per-option point fields; coupon validity windows/single-use tracking/percent caps; typed shipping policy engine (tiers, zone surcharges, COD); payment methods with deposit-waiting orders and expiry sweep; guest order inquiry with deposit-waiting self-cancellation; catalog search/sort/pagination; retry-visibility clock fix. 120 tests.

Coordinator verified after every round: build/typecheck, full suite with DB up, green suite with DB down, idempotent `db:migrate`, no `db:generate` diff.

Still open (product decisions, not engineering): 상품정보고시 (commerce B5, KR market), plus the undecided items listed in each repo's `docs/legacy-gap-audit.md`.
