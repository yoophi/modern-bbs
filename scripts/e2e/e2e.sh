#!/usr/bin/env bash
# E2E integration verification for modern-bbs services.
# Verifies real REST wiring: Common lifecycle projection events -> Community inbox
# (HTTP delivery), envelope replay -> Commerce inbox, and outbox/inbox state.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COMMON="$ROOT/../modern-bbs-common"
COMMUNITY="$ROOT/../modern-bbs-community"
COMMERCE="$ROOT/../modern-bbs-commerce"
LOGDIR="$(mktemp -d /tmp/modern-bbs-e2e.XXXXXX)"
PASS=0; FAIL=0
declare -a PIDS=()

note() { printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
ok() { PASS=$((PASS+1)); echo "PASS: $*"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL: $*"; }

psqlc() { docker exec modern-bbs-common-postgres-1 psql -U modern_bbs -d modern_bbs_common -tA -c "$1"; }
psqlm() { docker exec modern-bbs-community-postgres-1 psql -U modern_bbs -d modern_bbs_community -tA -c "$1"; }
psqlz() { docker exec modern-bbs-commerce-postgres-1 psql -U modern_bbs -d modern_bbs_commerce -tA -c "$1"; }

cleanup() {
  note "stopping servers"
  for pid in "${PIDS[@]:-}"; do kill "$pid" 2>/dev/null; done
  wait 2>/dev/null
}
trap cleanup EXIT

# --- preflight ------------------------------------------------------------
note "starting postgres containers"
(cd "$COMMON" && npm run db:up >/dev/null 2>&1)
(cd "$COMMUNITY" && npm run db:up >/dev/null 2>&1)
(cd "$COMMERCE" && npm run db:up >/dev/null 2>&1)
sleep 2

note "building services"
(cd "$COMMON" && npm run build >/dev/null 2>&1) || { bad "common build"; exit 1; }
(cd "$COMMUNITY" && npm run build >/dev/null 2>&1) || { bad "community build"; exit 1; }
(cd "$COMMERCE" && npm run build >/dev/null 2>&1) || { bad "commerce build"; exit 1; }

note "starting servers (logs: $LOGDIR)"
PORT=4011 PERSISTENCE_DRIVER=postgres \
  DATABASE_URL=postgres://modern_bbs:modern_bbs@localhost:5411/modern_bbs_common \
  EVENT_DELIVERY_URL=http://localhost:4012/internal/events \
  node "$COMMON/dist/index.js" >"$LOGDIR/common.log" 2>&1 &
PIDS+=($!)
PORT=4012 COMMUNITY_STORE=postgres \
  DATABASE_URL=postgres://modern_bbs:modern_bbs@localhost:5412/modern_bbs_community \
  node "$COMMUNITY/dist/index.js" >"$LOGDIR/community.log" 2>&1 &
PIDS+=($!)
PORT=4013 COMMERCE_PERSISTENCE=postgres COMMON_BASE_URL=http://localhost:4011 \
  DATABASE_URL=postgres://modern_bbs:modern_bbs@localhost:5413/modern_bbs_commerce \
  node "$COMMERCE/dist/index.js" >"$LOGDIR/commerce.log" 2>&1 &
PIDS+=($!)

wait_health() {
  for _ in $(seq 1 40); do
    curl -sf "http://localhost:$1/health" >/dev/null 2>&1 && return 0
    sleep 0.5
  done
  return 1
}
for svc in 4011:common 4012:community 4013:commerce; do
  port="${svc%%:*}"; name="${svc##*:}"
  if wait_health "$port"; then ok "health $name (:$port)"; else bad "health $name (:$port)"; tail "$LOGDIR/$name.log"; exit 1; fi
done

# --- S2: Common lifecycle -> projection event -> HTTP delivery -> Community inbox
note "S2: register member on common (email certification default ON)"
STAMP="$(date +%s)$RANDOM"
REGISTER=$(curl -sf -X POST http://localhost:4011/members \
  -H 'content-type: application/json' \
  -d "{\"loginId\":\"e2e-$STAMP\",\"displayName\":\"E2E Member\",\"contactEmail\":\"e2e-$STAMP@example.com\"}")
MEMBER_ID=$(echo "$REGISTER" | jq -r '.memberId // .member.id // .id')
[ -n "$MEMBER_ID" ] && [ "$MEMBER_ID" != "null" ] && ok "registered member $MEMBER_ID" || { bad "register"; echo "$REGISTER"; exit 1; }

FACTS=$(curl -sf "http://localhost:4011/members/$MEMBER_ID/facts")
STATUS0=$(echo "$FACTS" | jq -r '.member.status // .status')
VERIFIED0=$(echo "$FACTS" | jq -r '.member.emailVerified // .emailVerified')
[ "$STATUS0" = "ACTIVE" ] && ok "member ACTIVE with emailVerified=$VERIFIED0 (gating on login, not status)" || note "member initial status: $STATUS0"

note "S2: verify email to activate member"
CASE=$(curl -sf -X POST "http://localhost:4011/members/$MEMBER_ID/verification-cases" \
  -H 'content-type: application/json' \
  -d "{\"channel\":\"EMAIL\",\"target\":\"e2e-$STAMP@example.com\"}")
CASE_ID=$(echo "$CASE" | jq -r '.case.id // .id // .caseId')
CODE=$(echo "$CASE" | jq -r '.code // .case.code // .verificationCode')
if [ -z "$CODE" ] || [ "$CODE" = "null" ]; then
  CASE_ID=$(psqlc "select id from verification_cases where member_id='$MEMBER_ID' order by created_at desc limit 1")
  CODE=$(psqlc "select code from verification_cases where id='$CASE_ID'")
fi
[ -n "$CODE" ] && [ "$CODE" != "null" ] && ok "verification case $CASE_ID (code obtained)" || { bad "verification case"; exit 1; }
curl -sf -X POST "http://localhost:4011/verification-cases/$CASE_ID/verify" \
  -H 'content-type: application/json' -d "{\"code\":\"$CODE\"}" >/dev/null \
  && ok "email verified" || { bad "verify"; exit 1; }

STATUS1=$(curl -sf "http://localhost:4011/members/$MEMBER_ID/facts" | jq -r '.member.emailVerified // .emailVerified')
[ "$STATUS1" = "true" ] && ok "emailVerified=true after verification" || bad "emailVerified after verify: $STATUS1"

note "S2: waiting for projection event delivery -> community (max 30s)"
PROJ=""
for _ in $(seq 1 60); do
  PROJ=$(psqlm "select status from member_projections where member_id='$MEMBER_ID'")
  [ "$PROJ" = "ACTIVE" ] && break
  sleep 0.5
done
[ "$PROJ" = "ACTIVE" ] && ok "community projection ACTIVE for $MEMBER_ID" || bad "community projection status: '${PROJ:-absent}'"

PUBLISHED=$(psqlc "select count(*) from outbox_events where event_type='MemberProjectionUpdated' and aggregate_id='$MEMBER_ID' and published_at is not null")
UNPUBLISHED=$(psqlc "select count(*) from outbox_events where event_type='MemberProjectionUpdated' and aggregate_id='$MEMBER_ID' and published_at is null")
[ "$UNPUBLISHED" = "0" ] && [ "$PUBLISHED" -ge 1 ] && ok "common outbox rows published ($PUBLISHED)" || bad "outbox publish state published=$PUBLISHED unpublished=$UNPUBLISHED"

INBOXM=$(psqlm "select count(*) from inbox_events where event_type='MemberProjectionUpdated' and status='PROCESSED'")
[ "$INBOXM" -ge 1 ] && ok "community inbox processed projection events ($INBOXM)" || bad "community inbox processed count: $INBOXM"

# --- S3: replay the real envelope from common outbox -> commerce inbox -------
note "S3: replay MemberProjectionUpdated envelope to commerce /internal/events"
ENVELOPE=$(psqlc "select jsonb_strip_nulls(json_build_object('eventId', id, 'eventType', event_type, 'schemaVersion', schema_version, 'aggregateId', aggregate_id, 'aggregateVersion', aggregate_version, 'occurredAt', occurred_at, 'correlationId', correlation_id, 'causationId', causation_id, 'data', payload)::jsonb)::text from outbox_events where event_type='MemberProjectionUpdated' and aggregate_id='$MEMBER_ID' order by seq desc limit 1")
HTTP_CODE=$(curl -s -o /tmp/e2e-commerce-recv.json -w '%{http_code}' -X POST http://localhost:4013/internal/events \
  -H 'content-type: application/json' -H 'x-source-service: modern-bbs-common' \
  -d "$ENVELOPE")
[ "$HTTP_CODE" = "202" ] && ok "commerce accepted envelope (202)" || bad "commerce receive HTTP $HTTP_CODE: $(cat /tmp/e2e-commerce-recv.json)"

PROJZ=""
for _ in $(seq 1 40); do
  PROJZ=$(psqlz "select status from member_projections where member_id='$MEMBER_ID'")
  [ "$PROJZ" = "ACTIVE" ] && break
  sleep 0.5
done
[ "$PROJZ" = "ACTIVE" ] && ok "commerce projection ACTIVE for $MEMBER_ID" || bad "commerce projection status: '${PROJZ:-absent}'"

# duplicate delivery must be idempotent
EID=$(echo "$ENVELOPE" | jq -r '.eventId')
curl -s -o /dev/null -X POST http://localhost:4013/internal/events \
  -H 'content-type: application/json' -H 'x-source-service: modern-bbs-common' \
  -d "$ENVELOPE"
DUPES=$(psqlz "select count(*) from inbox_events where event_id='$EID'")
[ "$DUPES" -le 1 ] && ok "duplicate envelope deduped (rows: $DUPES)" || bad "duplicate rows: $DUPES"

# --- summary ----------------------------------------------------------------
note "E2E RESULT: PASS=$PASS FAIL=$FAIL (logs: $LOGDIR)"
[ "$FAIL" -eq 0 ]
