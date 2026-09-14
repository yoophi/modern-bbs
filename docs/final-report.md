# Modern BBS final verification report

Date: 2026-09-15

## Repositories

| Service | Path | Latest commit |
|---|---|---|
| Common | `/Users/yoophi/project/modern-bbs-common` | `9f34c13 feat: add cross-service contract guards` |
| Community | `/Users/yoophi/project/modern-bbs-community` | `d54b35d feat: add cross-service contract guards` |
| Commerce | `/Users/yoophi/project/modern-bbs-commerce` | `b174940 feat: add cross-service contract guards` |
| Planning/research | `/Users/yoophi/project/modern-bbs` | `403c83d docs: record milestone reviews and commits` |

## Final verification commands

All three service repos passed:

```bash
npm run typecheck
npm test
npm run build
npm run lint
npm run db:generate
DATABASE_URL=postgres://modern_bbs:modern_bbs@localhost:<service-port>/<service-db> npm run db:migrate
```

Migration smoke used each repo's `docker-compose.yml` PostgreSQL service.

Test counts at final verification:

| Service | Test files | Tests |
|---|---:|---:|
| Common | 4 | 10 |
| Community | 3 | 7 |
| Commerce | 3 | 6 |

## Architecture and contracts delivered

Each repo contains:

- Hono HTTP app with `/health` and `/capabilities`.
- Drizzle PostgreSQL schema and generated migrations.
- TypeScript build/typecheck/lint/test scripts.
- `docs/architecture.md` with hexagonal boundaries.
- `docs/api.md` with service API contract.
- `docs/contracts.md` with canonical errors, event envelope and idempotency rules.
- `src/domain/contracts.ts` and `src/application/inbox.ts` for capability and idempotent inbox semantics.
- Review records under `docs/reviews/`.

## Implemented legacy feature mapping

### Common

| Legacy area | Implemented target slice |
|---|---|
| Login/session actor | `POST /identity/verify`, `Actor`, in-memory Identity adapter |
| Member facts/status | `POST /members`, `GET /members/{id}/facts`, `PATCH /members/{id}/status` |
| Member lifecycle events | `MemberActivated`, `MemberSuspended`, `MemberWithdrawn`, `MemberAnonymizationRequested` style events |
| Platform grants | `POST /authorization/grants`, `POST /authorization/decisions`, batch decisions |
| Points ledger | balance, grant, reserve, commit, release, reverse APIs and tests |
| Provider seam | service-owned ports and in-memory adapter; provider SDKs excluded from domain/application |

### Community

| Legacy area | Implemented target slice |
|---|---|
| Board/group policy | board creation and typed `BoardPolicy` admin APIs |
| Posts | create/list/search/detail, secret post access, attachment `AssetId` refs |
| Comments/replies | comment creation/listing with author snapshot |
| Reactions | one reaction per member/post with duplicate prevention |
| Moderation | moderation case open/action/delete-post workflow |
| Membership coupling | local `CommunityMemberProjection`; Common connection as ports only |
| Points rewards | `PostPublished` and `CommentAdded` outbox events |

### Commerce

| Legacy area | Implemented target slice |
|---|---|
| Catalog/product | product admin/list/detail with stock field |
| Pricing/promotion | coupon and checkout quote with policy version/expiry |
| Cart/wishlist | guest/member cart, claim, cart lines, wishlist |
| Checkout/order | idempotent order submission with order snapshots |
| Payment | in-memory payment authorization stub |
| Inventory | stock adjustment and checkout stock commit/restoration on cancel |
| Fulfillment | shipment create/dispatch and order shipped transition |
| Review/Q&A | product review and inquiry APIs |
| Reporting | simple sales report |

## Exclusions honored

- React SPA/Admin SPA implementation not included.
- Custom template feature not implemented.
- Real PG integrations not implemented; payment is a stub/seam.
- Real SMS/email sending not implemented; outbox contracts exist.
- Legacy PHP compatibility layer not implemented.
- Legacy skin/theme runtime compatibility not implemented.

## Product decisions still open

- Guest checkout and guest-cart merge UX beyond the current explicit claim command.
- Suspended/withdrawn member permissions for existing posts/orders.
- Personal data retention/anonymization for posts, orders, reviews, Q&A and logs.
- Whether Community read/download point charging remains in scope.
- Point earning timing and partial cancellation/return reversal order.
- Points-provider outage UX: reject point-use checkout vs point-excluded requote.
- Projection maximum staleness per command.
- Quote validity duration and invalidation rules.
- Single tenant remains the default; multi-tenant not implemented.

## Coupling audit

Command:

```bash
rg -n "modern-bbs-(common|community|commerce)|from ['\"].*\.\./\.\./\.\./modern-bbs" src test docs --glob '!docs/reviews/**'
rg -n "@aws|stripe|kcp|inicis|toss|nicepay|openfga|auth0|keycloak|provider|DTO|sdk" src/domain src/application src/ports
rg -n "TODO|FIXME" src test docs
```

Result:

- No cross-service implementation imports found.
- No provider SDK/DTO usage found in `src/domain`, `src/application`, or `src/ports`.
- No TODO/FIXME markers found in `src`, `test`, or `docs`.
- Expected self-identifying service names appear only in `service-info.ts` and `contracts.ts`.

## Remaining engineering risks

- Application services are currently in-memory behavioural slices. PostgreSQL repositories are not fully wired to application services yet.
- Outbox/inbox semantics are implemented and tested, but persistent publisher/consumer workers are not production-grade.
- OpenAPI YAML generation is deferred; current equivalent artifacts are `docs/api.md`, `docs/contracts.md` and `/capabilities`.
- Payment, points, coupon and inventory compensation workflows are simplified stubs and need stronger process-state persistence before production.
- `npm install` reported moderate transitive vulnerabilities during scaffold creation; dependency hardening is required before release.

## Operating notes

For each service:

```bash
npm install
npm run typecheck
npm test
npm run build
npm run lint
npm run db:generate
npm run db:up
DATABASE_URL=postgres://modern_bbs:modern_bbs@localhost:<port>/<db> npm run db:migrate
npm run db:down
npm run dev
```

Host PostgreSQL ports:

- Common: `5411`, DB `modern_bbs_common`
- Community: `5412`, DB `modern_bbs_community`
- Commerce: `5413`, DB `modern_bbs_commerce`

## Conclusion

The three independent backend repositories exist, build, test and migrate independently. They implement first-pass core domain workflows and canonical contract seams for the Common, Community and Commerce services while preserving the key architectural constraints: one write owner per data area, no cross-service DB access, Common usage through ports/contracts, typed domain policies, idempotency, and outbox/inbox semantics.
