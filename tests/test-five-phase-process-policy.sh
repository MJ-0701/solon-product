#!/usr/bin/env bash
# 새 5단계 정책, 단일 산출물 소유권과 기존 Gate 호환 경계를 검증한다.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CTX="${DIST_DIR}/templates/.sfs-local-template/context"
POLICY="${CTX}/policies/lean-procedure-refactor-pack.md"
KO="${CTX}/policies/lean-procedure-refactor-pack.ko.md"
METHOD="${DIST_DIR}/docs/maintenance/methodology-7-step.md"
ADR="${DIST_DIR}/docs/maintenance/adr-policy.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -Fq -- "$2" "$1" || fail "${1##*/}: missing '$2'"; }
section() {
  awk -v start="$2" -v end="$3" '
    index($0, start) == 1 { active=1 }
    active { print }
    active && index($0, end) == 1 { exit }
  ' "$1"
}

# Both locale routes and the existing user guide expose exactly five phases.
for file in "${POLICY}" "${KO}" "${METHOD}"; do
  [[ "$(grep -Ec '^\| [1-5] \|' "${file}")" -eq 5 ]] || fail "${file}: expected five phase rows"
  for phase in 1 2 3 4 5; do
    [[ "$(grep -Fc "| ${phase} |" "${file}")" -eq 1 ]] || fail "${file}: missing or duplicate phase ${phase}"
  done
  if grep -Eq '^\| ([6-9]|[0-9]{2,}) \|' "${file}"; then
    fail "${file}: extra default phase"
  fi
  for artifact in requirement.md architecture-design.md api-contract.md implementation.md retro.md report.md; do
    has "${file}" "${artifact}"
  done
  [[ "$(head -n 1 "${file}")" == '---' ]] || fail "${file}: frontmatter missing"
  has "${file}" 'load_when:'
  [[ "$(wc -l < "${file}" | tr -d '[:space:]')" -le 200 ]] || fail "${file}: line budget exceeded"
done
has "${POLICY}" 'Use at most five phases'
has "${POLICY}" 'not a new CLI command'
has "${CTX}/kernel.md" 'For new work, load `policies/lean-procedure-refactor-pack.md`'
has "${CTX}/_INDEX.md" 'For new work, load `policies/lean-procedure-refactor-pack.md`'
has "${CTX}/_INDEX.md" 'policies/lean-procedure-refactor-pack.ko.md'
has "${METHOD}" 'lean-procedure-refactor-pack.ko.md'
echo 'PASS: five-phase default is routed and documented in both locales'

# Inspect the owner column, not mere mentions elsewhere (including references).
ownership="$(section "${POLICY}" '### Artifact ownership' '### One human review')"
owner() {
  printf '%s\n' "${ownership}" | awk -F '|' -v key="\`$1\`" '
    { artifact=$2; gsub(/^[ \t]+|[ \t]+$/, "", artifact) }
    artifact == key { print $3 }
  '
}
owns() {
  [[ "$(owner "$1")" == *"$2"* ]] || fail "$1 does not own $2"
  count="$(printf '%s\n' "${ownership}" | awk -F '|' -v term="$2" 'index($3, term) { n++ } END { print n+0 }')"
  [[ "${count}" -eq 1 ]] || fail "$2 must have exactly one owner, found ${count}"
}
for term in 'Bounded contexts' aggregates 'domain events' 'structural rationale'; do
  owns architecture-design.md "${term}"
done
owns api-contract.md 'External/API contract'
for term in 'Ordered work' 'TDD scenarios' 'migration/deploy checks'; do
  owns implementation.md "${term}"
done
owns retro.md 'Internal learning'
for term in Outcome evidence risks 'next step' 'useful handoff'; do
  owns report.md "${term}"
done
for artifact in requirement.md architecture-design.md api-contract.md implementation.md retro.md report.md; do
  [[ "$(owner "${artifact}" | wc -l | tr -d '[:space:]')" -eq 1 ]] || fail "duplicate owner row: ${artifact}"
done
[[ "$(owner api-contract.md)" != *'structural rationale'* ]] || fail 'API owns architecture prose'
[[ "$(owner implementation.md)" != *'External/API contract'* ]] || fail 'implementation owns API prose'
has "${POLICY}" 'Each concern has one owner.'
has "${POLICY}" 'copying prose; changes update that owner'
echo 'PASS: canonical ownership separates architecture, API, execution, learning, and handoff'

review="$(section "${POLICY}" '### One human review' '### Conditional ADR')"
for rule in 'Default human review happens once, after phase 4' 'before phase 5 closeout' \
  'automated/mechanical checks of contract completeness and test-plan coverage only' \
  'not a human approval gate' 'requirement.md' 'architecture-design.md' 'api-contract.md' 'implementation.md' \
  'reviewed code/artifact revisions, evidence, and decision' \
  'Reopening this review is risk-triggered only' irreversible high-cost high-risk \
  cross-team 'API compatibility' security 'data migration' 'explicit contract or architecture change' \
  'unresolved substantive review objection' 'failed quality gate' \
  'same implementation and contract remain unchanged'; do
  [[ "${review}" == *"${rule}"* ]] || fail "review contract missing: ${rule}"
done
has "${POLICY}" 'failed check into PASS or bypasses an unresolved objection'
has "${KO}" '기본 사람 검토 1회'
has "${KO}" '미해결 실질적 검토 이의'
has "${KO}" '품질 gate 실패'
for file in "${KO}" "${METHOD}"; do
  has "${file}" '4단계 구현·검증 후, 5단계 마무리 전에'
  has "${file}" '계약 완결성과 테스트 계획 커버리지의 자동/기계적 점검만'
  has "${file}" '사람 승인 gate가 아니다'
done
# Reject the superseded timing even if the new timing is also present.
for file in "${POLICY}" "${KO}" "${METHOD}"; do
  prose="$(tr '\n' ' ' < "${file}")"
  for stale in 'before TDD implementation' 'Before TDD, assess' \
    'substantive design/implementation-readiness review' 'design-review decision' \
    'TDD 구현 전에 한 번 검토' 'TDD 전에 **사람 검토' 'TDD 전에는 명세된 구현' \
    '설계/구현 준비도' '설계 검토 결정'; do
    [[ "${prose}" != *"${stale}"* ]] || fail "${file}: stale pre-TDD review rule: ${stale}"
  done
done
echo 'PASS: one human review follows phase 4 before phase 5; pre-coding checks are mechanical only'

for rule in 'substantive implementation-correctness review' 'not a line-by-line' \
  'long accumulation of tiny partial fixes' 'Judge only:' \
  'Overall direction against requirements' 'Implementation completeness and behavioral correctness' \
  'Architecture/domain boundaries and structural defects' 'Data, security, and operational risks' \
  'Missing critical tests' 'Inspect actual code, tests, and runtime evidence' \
  'only BLOCKER/HIGH findings and evidence' 'concise `PASS` or `BLOCKED`' \
  '`partial` is not a default human-review progress state' 'formatter/linter/CI or ignore them' \
  'Do not record or repeatedly fix line wrapping, formatting, naming nitpicks' \
  'ordinary code convention' 'must not create another human review cycle or reopen PASS' \
  'A nit alone is not a failed quality gate'; do
  [[ "${review}" == *"${rule}"* ]] || fail "substantive review rule missing: ${rule}"
done
# Assert dispositions in their severity rows, rather than accepting severity names alone.
for severity in BLOCKER HIGH; do
  row="$(printf '%s\n' "${review}" | grep -F "| ${severity} |")"
  [[ "${row}" == *'; blocks |' ]] || fail "${severity} must block"
done
has "${POLICY}" '| MEDIUM | Bounded non-blocking concern; track in the owning artifact only if it affects correctness or risk |'
has "${POLICY}" '| NIT | Non-blocking style/convention preference; omit from the human-review action list |'
for rule in '실제 구현 정확성 검토' '실제 코드·테스트·runtime evidence' '요구사항 대비 전체 방향' '구현 완결성과 동작 정확성' \
  '아키텍처/도메인 경계와 구조적 결함' '데이터·보안·운영 위험' '누락된 핵심 테스트' \
  'BLOCKER/HIGH 지적 및 근거' '`partial`을 기본 사람 검토 진행 상태로 사용하지 않는다' \
  '정확성이나 위험에 영향을 줄 때만' '사람 검토 action list에서 제외' \
  'formatter/linter/CI로 보내거나 무시한다' '추가 사람 검토 cycle을 만들거나 PASS를 다시 열 수 없다'; do
  has "${KO}" "${rule}"
done
for rule in '실제 코드·테스트·runtime evidence' 'BLOCKER/HIGH는 차단' 'MEDIUM은 정확성/위험 영향만 추적' \
  'NIT는 action list에서 제외' '비차단 nit로 재검토하지 않으며'; do has "${METHOD}" "${rule}"; done
echo 'PASS: substantive review scope and severity exclude nits and repeated human cycles'

adr_section="$(section "${POLICY}" '### Conditional ADR' '### Legacy compatibility')"
for term in 'not a default artifact' durable irreversible costly cross-team high-risk \
  'externally breaking' contested 'ADR-NNNN' registry lifecycle supersession \
  'references ADR IDs instead of duplicating full ADR content'; do
  [[ "${adr_section}" == *"${term}"* ]] || fail "ADR contract missing: ${term}"
done
for criterion in Durable Irreversible Costly Cross-team High-risk 'Externally breaking' Contested; do
  has "${ADR}" "| ${criterion} |"
done
has "${ADR}" 'adr-index.md'
has "${ADR}" 'superseded'
has "${DIST_DIR}/docs/maintenance/templates/adr-template.md" 'adr-policy.md의 Eligibility Gate'
echo 'PASS: ADR remains conditional with existing registry and lifecycle'

handoff="$(section "${POLICY}" '### Minimal durable documents' '### Legacy compatibility')"
for rule in 'minimal' 'durable set' 'Handoff is conditional' 'only for session' \
  interruption 'explicit pause/resume' 'long-running unfinished work' ownership \
  transfer 'blocker requiring another session' 'routine closeout uses `report.md`' \
  'must not be required or automatically generated for every task'; do
  [[ "${handoff}" == *"${rule}"* ]] || fail "conditional handoff rule missing: ${rule}"
done
for artifact in requirement.md architecture-design.md api-contract.md implementation.md retro.md report.md; do
  [[ "${handoff}" == *"${artifact}"* ]] || fail "durable artifact missing: ${artifact}"
done
for rule in 'handoff는 조건부다' '세션 중단' '명시적 일시정지/재개' '장기 미완료 작업' \
  '소유권 이전' '다른 세션이 필요한 blocker' '필수로 요구하거나 자동 생성해서는 안 된다'; do
  has "${KO}" "${rule}"
done
echo 'PASS: durable documents remain minimal; handoff requires an explicit continuity trigger'

compat="$(section "${POLICY}" '### Legacy compatibility' '## Keep / Shrink / Remove')"
for term in 'deprecated as the required human workflow' 'Existing commands remain supported' \
  'Gate 1–7' '.sfs-local/current-sprint' events.jsonl 'Do not rename, reset, migrate' \
  brainstorm.md plan.md implement.md 'not a drop-in filename rename' \
  'review.md` and `handoff.md` are not required authored artifacts' \
  'Legacy Gate 3/6 reviews still run' 'distinct from the single substantive human review' \
  'Gate 3 pre-coding checks do not require human approval' 'Gate 6 evidence does not replace' \
  'daily-handoff generation remains compatible, not a requirement for every new task' \
  'remain readable and' 'compatible for legacy work' \
  'Do not delete existing user workbench data in this slice' \
  'obsolete transient docs may be archived or removed only after' \
  'not referenced by active state/tests and preserving required' 'historical evidence' \
  'not runtime dispatch or artifact generation' 'separate compatible'; do
  [[ "${compat}" == *"${term}"* ]] || fail "compatibility contract missing: ${term}"
done
for file in "${KO}" "${METHOD}"; do
  has "${file}" 'Gate 3의 구현 전 점검은 사람 승인을 요구하지 않으며'
  has "${file}" 'Gate 6 evidence는 구현 후 사람 검토를 대체하지 않는다'
done
for file in "${KO}" "${METHOD}" "${ADR}"; do
  for rule in 'review.md' 'handoff.md' 'daily-handoff.md' '.html' '계속 읽을 수 있고 호환' \
    '활성 state/tests' '필수 이력 근거' '이번 slice'; do has "${file}" "${rule}"; done
done
for command in start brainstorm plan implement 'review --gate 3' 'review --gate 6' retro report; do
  [[ "${compat}" == *"sfs ${command}"* ]] || fail "legacy command missing: ${command}"
done
for command in start brainstorm plan implement review retro report; do
  has "${DIST_DIR}/templates/.sfs-local-template/scripts/sfs-dispatch.sh" "|${command}|"
  [[ -f "${DIST_DIR}/templates/.sfs-local-template/scripts/sfs-${command}.sh" ]] || fail "missing legacy script: ${command}"
done
# Exercise read-only routing through the real CLI; never start or modify a workbench.
for key in policies/lean-procedure-refactor-pack policies/lean-procedure-refactor-pack.ko \
  start brainstorm plan implement review tidy; do
  path="$(SFS_COMMAND_TIMEOUT_SEC=0 SFS_DIST_DIR="${DIST_DIR}" bash "${DIST_DIR}/bin/sfs" context path "${key}")"
  [[ -f "${path}" ]] || fail "unresolved existing context route: ${key}"
  case "${key}" in
    policies/*) expected="${key}.md" ;;
    *) expected="commands/${key}.md" ;;
  esac
  [[ "${path}" == "${CTX}/${expected}" ]] || fail "wrong distribution route: ${key}: ${path}"
done
echo 'PASS: legacy commands/state remain referenced and CLI context aliases resolve'
echo 'test-five-phase-process-policy: OK'
