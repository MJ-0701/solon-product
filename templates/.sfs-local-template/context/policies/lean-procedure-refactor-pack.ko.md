---
id: sfs-policy-lean-procedure-refactor-pack-ko
summary: 5단계 기본 흐름과 산출물 소유권, 위험 기반 사람 검토를 정의하고 기존 runtime gate를 보존한다.
load_when:
  - 새 작업
  - 기본 워크플로
  - five-phase
  - 절차 병목
  - 절차 리팩토링
  - ceremony
  - lean gate
  - slow review loop
  - 불필요한 절차
language: ko
status: filled-v1
---

# Lean Procedure Refactor Pack

새 작업의 기본 흐름과 SFS 자체 또는 SFS 프로젝트의 절차 축소에 사용한다.

## Five-phase default — 5단계 기본 흐름

`five-phase`는 새 작업의 간결한 프로세스 별칭이며 새 CLI 명령/flag가 아니다.
최대 5단계로 진행하며 자동 검증을 별도 사람 승인 단계로 늘리지 않는다.

| 단계 | 목적 | Canonical 산출물 |
|---|---|---|
| 1 | 요구사항/도메인 정렬 | `requirement.md` |
| 2 | DDD/시스템 설계 | `architecture-design.md` |
| 3 | 구현 계약 | `api-contract.md` + `implementation.md` |
| 4 | TDD 구현 및 검증 | 코드, 테스트, runtime evidence |
| 5 | 마무리 | 최소 `retro.md` + `report.md` |

### Artifact ownership — 산출물 소유권

관심사마다 소유 문서는 하나다. 본문을 복제하지 않고 소유 문서/섹션을 참조한다.
변경 시 소유 문서와 이를 참조하는 링크를 갱신한다.

| 산출물 | 소유 내용 | 참조만 하는 내용 |
|---|---|---|
| `requirement.md` | 의도, 도메인 용어, 범위/비목표, 인수 조건 | 설계와 실행 상세 |
| `architecture-design.md` | bounded contexts, aggregates, domain events, 구조적 근거 | API 상세, 작업 순서, ADR 본문 |
| `api-contract.md` | 외부/API 계약: 인터페이스, payload, 오류, 호환성 | 도메인 구조와 구현 순서 |
| `implementation.md` | 작업 순서, TDD 시나리오, migration/deploy 점검 | 요구사항, 아키텍처, 외부/API 계약 |
| `retro.md` | 내부 학습과 실행 가능한 개선 | report의 결과/evidence |
| `report.md` | 결과, evidence, 위험, 다음 단계 및 유용한 인계 내용 | 설계 본문과 내부 학습 |

### One human review — 기본 사람 검토 1회

코딩 전 3단계에서는 계약 완결성과 테스트 계획 커버리지의 자동/기계적 점검만 수행한다.
이는 사람 승인 gate가 아니다. `api-contract.md`와 `implementation.md`를
`requirement.md` 및 `architecture-design.md`에 대조한 뒤 4단계 TDD로 진행한다.
기본 사람 검토는 4단계 구현·검증 후, 5단계 마무리 전에 한 번 수행한다.
검토한 코드/문서 revision, evidence와 결정을 `implementation.md`에 기록하며
같은 구현과 계약이 유지되는 동안 동일 승인을 반복 요청하지 않는다.

이는 실질적인 실제 구현 정확성 검토이며 줄 단위 스타일 리뷰나 작은 부분 수정의
장기 누적이 아니다. 사람 검토 범위는 다음으로 한정한다:
- 요구사항 대비 전체 방향.
- 인수 조건 대비 실제 코드의 구현 완결성과 동작 정확성.
- 아키텍처/도메인 경계와 구조적 결함.
- 데이터·보안·운영 위험.
- 누락된 핵심 테스트.

실제 코드·테스트·runtime evidence를 요구사항 및 설계와 함께 검토한다.
테스트 계획이나 구현 명세만으로 정확성을 입증하지 않는다. 간결한 `PASS` 또는
`BLOCKED` 판정과 BLOCKER/HIGH 지적 및 근거(코드/문서/섹션 또는 테스트/runtime 결과)만 남긴다.
심각도는 아래와 같으며 `partial`을 기본 사람 검토 진행 상태로 사용하지 않는다:
| 심각도 | 의미와 처리 |
|---|---|
| BLOCKER | 치명적 정확성/안전 실패 또는 사용 불가능한 계약; 차단 |
| HIGH | 중대한 요구사항·완결성·경계·위험·핵심 테스트 결함; 차단 |
| MEDIUM | 비차단 문제; 정확성이나 위험에 영향을 줄 때만 소유 문서에서 추적 |
| NIT | 비차단 스타일/관례 취향; 사람 검토 action list에서 제외 |

줄바꿈, 포맷, 네이밍 잔소리, 일반 코드 관례 등 비차단 부분 개선은 사람 검토에서
기록하거나 반복 수정하지 않는다. formatter/linter/CI로 보내거나 무시한다.
비차단 nit는 추가 사람 검토 cycle을 만들거나 PASS를 다시 열 수 없다.
MEDIUM 추적만으로 재검토하지 않으며 중대한 영향은 BLOCKER/HIGH 기준으로 판단한다.

이 검토의 재개는 새로운 위험 발생 시에만 한다: 비가역·고비용·고위험·팀 간 영향·API
호환성·보안·데이터 마이그레이션 변경, 명시적 계약/아키텍처 변경, 미해결 실질적 검토 이의,
검토한 작업의 BLOCKER/HIGH 결함을 드러내는 품질 gate 실패.
nit만으로 품질 gate 실패라 하지 않는다. trigger와 영향 범위를 기록하고 해당 작업을
수정·검증한 뒤 같은 검토 시점으로 돌아온다. 구현 전 점검 실패는 수정 대상이며 사람 승인 gate가 아니다.
자동 테스트와 agent review는 계속 실행한다. 사람 검토 1회가 실패를 PASS로
바꾸거나 미해결 이의를 우회하는 근거가 되지 않는다.

### Conditional ADR — 조건부 ADR

ADR은 기본 산출물이 아니다. 지속적/비가역, 고비용, 팀 간 영향, 고위험,
외부 호환성 파괴 또는 이견이 있는 결정에만 작성한다. 사소하고 가역적인 선택은
소유 문서에 남긴다. 기존 `ADR-NNNN` ID, registry, lifecycle, supersession은
유지한다. `architecture-design.md`는 ADR ID를 참조하고 전체 본문을 복제하지 않는다.
이 배포 repo의 운영 규약은 `docs/maintenance/adr-policy.md`이며 consumer는
자신의 기존 ADR 체계와 경로를 유지한다.

### Minimal durable documents and conditional handoff — 최소 영속 문서와 조건부 인계

최소 영속 문서는 `requirement.md`, `architecture-design.md`, `api-contract.md`,
`implementation.md`, 기준에 해당하는 ADR, `retro.md`, `report.md`다.
handoff는 조건부다: 세션 중단, 명시적 일시정지/재개, 장기 미완료 작업, 소유권 이전,
다른 세션이 필요한 blocker가 있을 때만 `handoff.md`를 작성한다.
소유 문서를 복제하지 않고 연결하며 일반 마무리는 `report.md`에 둔다.
새 작업마다 `review.md`, `handoff.md`, `daily-handoff.md`, 파생 `.html`을
필수로 요구하거나 자동 생성해서는 안 된다.

### Legacy compatibility — 호환성과 deprecation

새 작업의 필수 사람 워크플로로서 기존 7-step/Gate 표기는 deprecated다.
기존 명령 `sfs start`, `sfs brainstorm`, `sfs plan`, `sfs implement`,
`sfs review --gate 3`, `sfs review --gate 6`, `sfs retro`, `sfs report`는 지원한다.
Gate 1–7 표기, 내부 gate ID, 테스트, `.sfs-local/current-sprint`, `events.jsonl`,
기존 consumer workbench는 호환 유지하며 이름 변경·초기화·이관·상태 조작하지 않는다.

이번 slice는 작성 정책만 바꾸며 runtime dispatch나 산출물 생성은 바꾸지 않는다.
`brainstorm.md`, `plan.md`, `implement.md`는 기존 runtime 입력으로 유효하다.
`implementation.md`로 `implement.md`를 단순 개명하지 않는다. 기존 필수 필드와
evidence를 보존하고 canonical 문서가 있으면 소유 문서로 연결한다.
기존 Gate 3/6 review는 계속 동작한다. agent/자동/runtime evidence는 실질적인
사람 검토 1회와 구별한다. 기존 runtime daily-handoff 생성은 호환 동작이며
모든 새 작업의 필수 요건이 아니다.
Gate 3의 구현 전 점검은 사람 승인을 요구하지 않으며
Gate 6 evidence는 구현 후 사람 검토를 대체하지 않는다.

새 작업에 `review.md`와 `handoff.md`를 별도 작성하도록 요구하지 않는다.
구현 후 사람 검토 결정은 `implementation.md`, 유용한 인계 내용은 `report.md`에 둔다.
별도 인계는 위 조건에서만 작성한다. 기존 `review.md`, `handoff.md`,
`daily-handoff.md`/`.html`은 legacy 작업에서 계속 읽을 수 있고 호환된다.
이번 slice에서 기존 사용자 workbench 데이터를 삭제하지 않는다.
CLI가 새 canonical 산출물만 생성·소비하려면 scaffolding, validator, projection을
호환 방식으로 전환하는 후속 slice가 필요하다.
향후 정리: 낡은 임시 문서는 활성 state/tests에서 참조하지 않음을 확인하고
필수 이력 근거를 보존한 뒤에만 archive 또는 삭제할 수 있다.
이 보존 규칙은 이번 slice의 정리 실행을 허용하지 않는다.

## Keep / Shrink / Remove

- 보안, 데이터 손실, 공개 contract, 회귀, release, user judgment 실패를 막고
  테스트로 싸게 대체하기 어려운 step 은 유지한다.
- 가치가 있지만 사용자 눈에 보이는 의식일 필요가 없으면 auto-lens, checklist row,
  template field, post-run assertion 으로 축소한다.
- stronger evidence 를 중복하거나, user 에게 runnable work 를 맡기거나,
  mainline 을 반복해서 막는 ceremony 는 제거하거나 downgrade 한다.
- invariant 는 제거하지 않는다. evidence path 를 자동화, 축소, 인접 gate 통합,
  waiver 로 바꾼다.

## Bottleneck Ledger

의미 있는 signal 만 기록한다.

- user-call count, runnable-step delegation count, review loop count.
- auth/tool setup 에 막힌 시간과 main objective 진행 시간의 차이.
- 반복 finding category 와 더 이른 guard/test 로 잡을 수 있는지.
- token/context growth, stale artifact, manual copy-paste handoff.
- command/test/runtime wait 를 parallel, cache, targeted 로 바꿀 수 있는지.

## Refactor Rule

결과는 절차는 줄고 품질은 같거나 강해야 한다.

- manual prompt 와 반복 review 감소.
- trigger condition 명확화와 context load 축소.
- test, smoke, ledger, release verifier evidence 는 같거나 강함.
- security, data validation, DDD/TDD, user approval safety 는 약화 금지.

## Process self-audit

각 gate, review loop, 반복 checklist, ceremony 마다 묻는다: 이 gate 또는 ceremony 가 현재 objective 에 여전히 기여하고 실제 실패를 막는가?

- 그렇다면 invariant 는 유지하고 evidence path 만 더 싸게 만든다.
- 일부만 그렇다면 auto-lens, template row, post-run assertion 으로 축소한다.
- 아니라면 ceremony 를 보존하지 말고 제거, downgrade, defer, 또는 명시적
  waiver 로 처리한다.

## Anti-yak cadence

anti-yak cadence 는 hard blocker 가 아니라 권고다: 3 meta-system WUs 뒤에는
최소 1 user-outcome WU 를 일정에 넣거나 owner reason 이 있는 waiver 를 남긴다.
user-outcome WU 는 SFS 방법론 자체가 아니라 실제 product/user 결과를 전진시키는
작업이고, meta-system WU 는 SFS process, policy, template, review rail,
instrumentation 을 바꾸는 작업이다.
