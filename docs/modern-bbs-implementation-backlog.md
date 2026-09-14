# Modern BBS implementation backlog

Date: 2026-09-14

## Purpose

This is the working backlog for rewriting Gnuboard5 5.6.38 / Youngcart into three independent Hono + Drizzle ORM + PostgreSQL backend services:

- `/Users/yoophi/project/modern-bbs-common`
- `/Users/yoophi/project/modern-bbs-community`
- `/Users/yoophi/project/modern-bbs-commerce`

It consolidates the authoritative Logseq Modern BBS pages, repo research documents, and the legacy source at `/Users/yoophi/project/ext/gnuboard5`.

## Baseline sources rechecked

### Repo research documents

- `docs/research-index.md`
- `docs/gnuboard5-member-youngcart-analysis.md`
- `docs/gnuboard5-platform-characterization.md`
- `docs/bounded-context-proposal.md`
- `docs/community-decoupling-proposal.md`
- `docs/commerce-core-decoupling-proposal.md`
- `docs/pluggable-common-services-architecture.md`
- `docs/service-feature-catalog.md`

### Logseq pages already loaded as session context

- `/Users/yoophi/docs/private-zk/pages/Modern BBS.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F01 Gnuboard5 플랫폼 분석.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F02 Bounded Context 제안.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F03 게시판과 공통 기능 분리.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F04 쇼핑몰과 공통 기능 분리.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F05 교체 가능한 공통 서비스 계약.md`
- `/Users/yoophi/docs/private-zk/pages/Modern BBS%2F06 공통 기능 게시판 영카트 기능 카탈로그.md`

### Legacy source touchpoints

- Schemas: `install/gnuboard5.sql`, `install/gnuboard5shop.sql`
- Common bootstrap/config: `common.php`, `shop.config.php`, `extend/*.php`
- Common/community entrypoints: `bbs/*.php`, `adm/*.php`
- Commerce entrypoints: `shop/*.php`, `mobile/shop/*.php`, `adm/shop_admin/*.php`
- Core libraries: `lib/common.lib.php`, `lib/shop.lib.php`, `lib/shop.cartvalidate.lib.php`, mail/SMS/editor/thumbnail helpers
- Payment/provider directories: `shop/kcp`, `shop/inicis`, `shop/toss`, `shop/nicepay`, `shop/lg`, `shop/naverpay`, `shop/kakaopay`

## Legacy table inventory and target ownership

### Common / platform tables

| Legacy table | Target owner | Notes |
|---|---|---|
| `g5_member` | Common Membership + Identity split | Credentials/session identifiers, profile, member status, verification, consent-ish flags, point cache must be split. |
| `g5_member_auto_login` | Common Identity | Refresh/remember-me session equivalent. |
| `g5_member_social_profiles` | Common Identity | External identity links. |
| `g5_cert_history`, `g5_member_cert_history` | Common Membership Verification | Verification cases/history. |
| `g5_auth` | Common Platform Authorization | Admin menu grants; domain resource policies stay in Community/Commerce. |
| `g5_point` | Common Points/Loyalty | Ledger source; `g5_member.mb_point` becomes projection/cache only. |
| `g5_config` | Split | Platform config only; domain policies move to owning services. |
| `g5_login`, `g5_visit`, `g5_visit_sum`, `g5_popular` | Analytics/Platform Operations | Not part of core business write paths. |
| `g5_mail` | Notification/Campaign admin | Real sending out of scope; adapter stub and outbox contract only. |
| `g5_content`, `g5_faq`, `g5_faq_master`, `g5_new_win`, `g5_menu` | CMS/Platform shell | Backlog/supporting scope; not core service rule owner. |
| `g5_migrations`, `g5_uniqid` | Migration/tooling | Not domain tables. |

### Community tables

| Legacy table | Target owner | Notes |
|---|---|---|
| `g5_group`, `g5_group_member` | Community | Board groups and group membership/admin policy. |
| `g5_board` | Community | Board metadata and typed `BoardPolicy`. |
| Per-board write tables | Community | New model uses one common posts/comments model, not per-board physical tables. |
| `g5_board_file` | Community + Media | Store `AssetId`/attachment reference; Media handles storage/transforms. |
| `g5_board_good` | Community | Reactions/recommendations. |
| `g5_board_new` | Community Search/Feed projection | Latest post/comment feed. |
| `g5_scrap` | Community | Bookmark/scrap. |
| `g5_autosave` | Community | Draft/autosave. |
| `g5_memo` | Community Messaging optional module | Include unless explicitly descoped later. |
| `g5_poll`, `g5_poll_etc` | Community Engagement optional module | Product decision still open, but backlog includes it. |
| `g5_qa_config`, `g5_qa_content` | Community Support optional module | 1:1 inquiry. |

### Commerce tables

| Legacy table | Target owner | Notes |
|---|---|---|
| `g5_shop_category` | Commerce Catalog | Category tree. |
| `g5_shop_item`, `g5_shop_item_option`, `g5_shop_item_relation` | Commerce Catalog | Product, option/variant, relations. |
| `g5_shop_cart` | Commerce Cart + Ordering split | Must split cart line from order line. |
| `g5_shop_order`, `g5_shop_order_data`, `g5_shop_order_delete`, `g5_shop_order_cancel_log`, `g5_shop_order_post_log` | Commerce Ordering/Payment audit | Order header, process state, cancellation/audit data. |
| `g5_shop_coupon`, `g5_shop_coupon_log`, `g5_shop_coupon_zone` | Commerce Pricing & Promotion | Coupon definition, issuance/use logs, zone. |
| `g5_shop_default` | Split into typed policies | Catalog/Pricing/Cart/Ordering/Inventory/Fulfillment/Payment/Loyalty policies; secrets to infra config. |
| `g5_shop_banner`, `g5_shop_event`, `g5_shop_event_item` | Commerce Catalog/Promotion | Campaign/display and click tracking. |
| `g5_shop_item_use` | Commerce Review | Product review/rating. |
| `g5_shop_item_qa` | Commerce Product Q&A | Secret inquiry access policy. |
| `g5_shop_wish` | Commerce Wishlist | Wishlist. |
| `g5_shop_order_address` | Commerce Customer/Ordering | Address book / order address input; order stores snapshots. |
| `g5_shop_sendcost` | Commerce Fulfillment/Pricing | Shipping cost records. |
| `g5_shop_item_stocksms` | Commerce Inventory + Notification | Back-in-stock subscription; SMS send stub only. |
| `g5_shop_personalpay` | Commerce Payment | Personal payment requests. |
| `g5_shop_inicis_log`, `g5_shop_inicis_pay`, `g5_shop_inicis_pay_event`, `g5_shop_kcp_noti` | Commerce Payment adapter/audit | Provider event/audit payloads. |

## Service backlogs

## 1. Common Service backlog

### Identity

- OIDC/OAuth-first contract profile and local test credential adapter.
- Principal, credential/session, refresh/remember-me session, external identity mapping.
- `Actor` creation from credential with trust boundary: no provider claims in domain.
- Login/logout/session list/revoke APIs for local implementation or adapter seam.
- Password recovery/reset compatibility seam for legacy migration.

### Membership

- Member lifecycle: register, activate, suspend, reinstate, withdraw, anonymize.
- Profile facts, display name, contact fields, consent and verification facts.
- Verification cases for email, phone, identity, adult verification.
- Minimal `getMemberFacts(fields, minimumVersion?)` API.
- Lifecycle events: activated/profile changed/verification changed/segments changed/suspended/withdrawn/anonymization requested.
- Admin member search/update/export with privacy controls.
- In-memory provider and legacy `g5_member` anti-corruption adapter seam.

### Platform Authorization

- Platform roles/grants and admin menu grants.
- Canonical `authorize` / `authorizeBatch` decisions: `ALLOW`, `DENY`, `INDETERMINATE`.
- Policy version and decision audit metadata.
- Legacy `mb_level`/`g5_auth` mapping adapter.
- Important boundary: no ownership of board/order aggregate invariants.

### Points / Loyalty

- Point account, ledger, reservation, expiration/reversal model.
- Query: balance and transaction page.
- Commands: `reserve`, `commit`, `release`, `grant`, `reverse`.
- Idempotency conflict handling and timeout-outcome-unknown lookup semantics.
- Canonical references: `COMMUNITY` or `COMMERCE` source, stable source type/id.
- Conformance tests for negative-balance prevention, concurrent reservation, duplicate commit/release, reversal, expiration races.

### Technical capabilities in Common scope

- Notification: contract + outbox consumer stub only; no real SMS/mail send.
- Media: asset metadata/upload intent contract and in-memory/local adapter; domain services own access decisions.
- Security: CAPTCHA/action-token/rate-limit/sanitization adapter seams where needed.
- Platform operations/CMS/Analytics: backlog/supporting modules, not core shared business rule dumping ground.

## 2. Community Service backlog

### Board/group administration

- Board groups, boards, board creation/copy/delete.
- `BoardPolicy`: visibility, read/write/comment/download policy, secret post, verification requirements, attachments, moderation, points reward/cost references.
- Board/group admin assignment and capability query.
- Admin APIs for board/group policy management.

### Posts

- Unified posts model instead of per-board physical tables.
- List/detail/create/revise/delete.
- Replies/threading, notices, secret posts, categories.
- HTML/editor content handling via sanitization policy.
- External links and link-click recording.
- Attachments as `AssetId` references with Community access policy.
- View counts and read markers where needed.
- Autosave/drafts.
- RSS/feed support if retained as API/feed adapter.

### Comments and reactions

- Comments and replies, revise/delete.
- Recommendation/disrecommend reactions with duplicate prevention.
- Scrap/bookmark.
- Latest posts/comments feed and search projection.

### Search and read models

- Board-local search and multi-board search.
- Author display snapshot and member projection; no Membership DB join or per-row provider calls.
- Capability-enriched board/post responses for current `Actor`.

### Moderation and adjacent modules

- Bulk delete, move/copy posts, content cleanup.
- Moderation cases/report/block workflow.
- 1:1 inquiry, memo, poll as optional adjacent Community modules unless later descoped.
- Community notification/outbox events, not direct mail/SMS.

### Common integration ports

- Identity port -> `Actor`.
- Membership projection + stale/latest facts policy.
- Authorization port only for platform grants; Community owns board/post policies.
- Points port for paid read/download/write if retained; activity rewards through outbox.

## 3. Commerce Service backlog

### Catalog

- Category tree.
- Product, option/variant, additional options, publication/sale state.
- Product images/assets, information notices, related products.
- Product display types: hit/recommended/new/popular/discount.
- Event/banner/campaign display and click tracking.
- Admin product/category/option/event/banner APIs, including bulk/Excel-like import adapter if feasible.

### Pricing & Promotion

- Price/option/additional option pricing.
- Tax, shipping cost calculation policy, minimum order policy.
- Coupon definitions: product/category/order/shipping coupons.
- Coupon zone, member-targeted coupon, point-purchased coupon process.
- Quote with applied policy versions and expiration.
- Coupon reserve/commit/release semantics for checkout.

### Cart / Wishlist

- Guest/member carts and cart lines.
- Add/change/remove/select lines with server-side price/product/option validation.
- Guest cart token and explicit `claimGuestCart` merge command.
- Cart retention and cleanup policy.
- Wishlist.

### Checkout / Ordering

- Idempotent `submitOrder` process manager.
- Customer/orderer/shipping snapshots.
- Order and order lines separated from cart lines.
- Order state and order-line state machines: pending payment/paid/preparing/shipped/completed/cancelled/returned/out-of-stock.
- Cancellation, partial cancellation, return request/approval.
- Order query/admin management APIs.
- Address book and order address APIs.
- Order mail/SMS outbox events only.

### Payment

- Payment interface: authorize/capture/void/refund/callback/reconcile.
- Provider adapter stubs for KCP, Inicis, Toss, Nicepay, LG, KakaoPay/NaverPay families; no real PG integration in this goal.
- Provider event storage, signature verification seam, duplicate callback handling, reconciliation case model.
- Personal payment requests.

### Inventory / Fulfillment

- Stock item, option stock, stock reservation with TTL, commit/release/adjust.
- Back-in-stock subscriptions with Notification event stub.
- Fulfillment orders, shipments, tracking info, dispatch/delivery/return receipt.
- Shipping fee records and admin shipping update/import APIs.

### Commerce Engagement / Reporting

- Product reviews/rating, moderation/admin approval where relevant.
- Product Q&A and secret Q&A access policy.
- Product recommendation mail as Notification event.
- Reporting: sales by day/month/year/period, selling rank, shipping cost, wishlist stats.

### Common integration ports

- Identity port -> `Actor`.
- Commerce member projection with status, verification and business segments.
- Authorization port only for platform/operator grants; Commerce owns catalog/promotion/order/inventory policies.
- Points reservation for checkout and point-coupon purchase; points grants/reversals through order events.

## Cross-service contracts and invariants

- No domain module imports provider SDKs or generated provider DTOs directly.
- No cross-service DB joins or writes.
- Every service keeps its own IDs; external provider IDs stay in adapter mapping tables.
- Events use a common envelope: `eventId`, `eventType`, `schemaVersion`, `aggregateId`, `aggregateVersion`, `occurredAt`, `correlationId`, optional `causationId`, optional `tenantId`, `data`.
- Synchronous calls are limited to operations that determine immediate command success: credential verification, platform grant decision, member facts when projection freshness is insufficient, quote validation, point/coupon/stock reservation, payment authorization.
- Outbox/inbox is required for rewards, notifications, analytics, projection updates, and anonymization workflows.
- Idempotency keys are required for order submission, payment commands, point commands, coupon issue/use, inventory reservations and event consumers.
- Canonical errors include at least: `INVALID_ARGUMENT`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `PROVIDER_UNAVAILABLE`, `TIMEOUT_OUTCOME_UNKNOWN`, `IDEMPOTENCY_CONFLICT`, `STALE_PROJECTION`, `CAPABILITY_UNSUPPORTED`.

## Explicit exclusions

- React SPA/Admin SPA implementation.
- Custom template feature implementation.
- Real PG production integrations; implement adapter contracts/stubs only.
- Real SMS/email delivery; implement Notification contract/stubs/outbox only.
- Legacy PHP compatibility layer.
- Direct support for legacy skin/theme runtime execution. Theme/skin belongs to future SPA/design-system work.

## Product decisions still required

1. Whether guest checkout remains supported and exact guest-cart merge UX.
2. What suspended members may do with existing posts/orders.
3. Withdrawal/anonymization policy for author names, order snapshots, reviews, Q&A, memo, inquiry and logs.
4. Whether read/download point charging is retained in Community.
5. Point earning timing: payment complete, shipping complete, delivery complete, or purchase confirmation.
6. Partial cancellation/return allocation order for coupon, shipping fee, tax, points and refund.
7. Whether points-provider outage should offer point-excluded requote or simply reject point-use checkout.
8. Purchase review ownership remains Commerce by default; only revisit if Community-style review is explicitly required.
9. Maximum staleness allowed for Community/Commerce membership projections.
10. Quote validity duration and which policy changes invalidate existing quotes.
11. Single-tenant vs multi-tenant support. Current default: single-tenant unless later changed.
12. Exact scope of adjacent Community modules: 1:1 inquiry, memo, poll.

## Milestone order

1. **Foundation and repo bootstrap**
   - Create three independent git repos.
   - Establish shared technical standards without sharing business helpers: TypeScript, Hono, Drizzle, PostgreSQL, test runner, lint/typecheck/build/migration scripts, project structure.
   - Define common API/error/event/idempotency conventions.

2. **Common service first vertical slice**
   - Identity actor verification, membership facts/events, platform grants, points ledger/reservation.
   - In-memory and test adapters.
   - Contract/conformance tests.
   - Commit after review and verification.

3. **Community first vertical slice**
   - Board + post + comment + member projection + points reward outbox.
   - Access policy and admin board policy APIs.
   - Commit after review and verification.

4. **Commerce first vertical slice**
   - Catalog + cart + quote + order submit with payment/stock/points stubs.
   - Order snapshot and idempotency.
   - Commit after review and verification.

5. **Community completion milestone**
   - Search/feed, reactions, attachments, moderation, adjacent modules selected for inclusion.
   - Contract/API documentation and tests.
   - Commit after review and verification.

6. **Commerce completion milestone**
   - Promotions/coupons, inventory/fulfillment, cancellations/returns, reviews/Q&A, reporting/admin APIs.
   - Contract/API documentation and tests.
   - Commit after review and verification.

7. **Cross-service reliability milestone**
   - Outbox/inbox, event schemas, idempotent consumers, provider capability checks, canonical error mapping, conformance tests across adapters.
   - Commit after review and verification.

8. **Final audit milestone**
   - Re-run build/typecheck/test/migrations in all repos.
   - Check for forbidden dependencies: cross-service DB access, provider DTO/SDK in domain, common helper business rules.
   - Update feature mapping, exclusions, unresolved product decisions and operating docs.
   - Final review, fixes and commit.

## Review/commit rule for every milestone

For each milestone:

1. Produce or update implementation artifacts.
2. Run relevant verification commands.
3. Perform one code review pass.
4. Apply at least one review-driven fix when findings exist; if no findings exist, record that explicitly.
5. Re-run verification.
6. Commit the milestone in the affected repo(s) with a clear message and record the commit hash.
