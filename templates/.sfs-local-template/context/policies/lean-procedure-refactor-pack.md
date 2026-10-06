---
id: sfs-policy-lean-procedure-refactor-pack
summary: Five-phase default, canonical artifact ownership, and risk-triggered human review; preserve legacy runtime gates.
load_when:
  - new work
  - default workflow
  - five-phase
  - process bottleneck
  - procedural refactor
  - ceremony
  - lean gate
  - slow review loop
  - unnecessary process
status: filled-v1
---

# Lean Procedure Refactor Pack

Use this pack for new work and when procedure slows SFS or an SFS-managed project.

## Five-phase default

`five-phase` is the concise process alias for new work, not a new CLI command
or flag. Use at most five phases; automated checks do not add human phases.

| Phase | Purpose | Canonical artifacts |
|---|---|---|
| 1 | Requirements/domain alignment | `requirement.md` |
| 2 | DDD/system design | `architecture-design.md` |
| 3 | Implementation contract | `api-contract.md` + `implementation.md` |
| 4 | TDD implementation and verification | Code, tests, runtime evidence |
| 5 | Closeout | Minimal `retro.md` + `report.md` |

### Artifact ownership

Each concern has one owner. Link to the owning artifact/section instead of
copying prose; changes update that owner and its dependent references.

| Artifact | Owns | References only |
|---|---|---|
| `requirement.md` | Intent, domain vocabulary, scope/non-goals, acceptance criteria | Design and execution details |
| `architecture-design.md` | Bounded contexts, aggregates, domain events, structural rationale | API details, ordered work, ADR content |
| `api-contract.md` | External/API contract: interfaces, payloads, errors, compatibility | Domain structure and implementation sequence |
| `implementation.md` | Ordered work, TDD scenarios, migration/deploy checks | Requirements, architecture, external/API contract |
| `retro.md` | Internal learning and actionable improvements | Outcome/evidence already in report |
| `report.md` | Outcome, evidence, risks, next step; useful handoff context | Design prose and internal learning |

### One human review, after implementation

Before coding, phase 3 uses automated/mechanical checks of contract completeness and test-plan coverage only;
this is not a human approval gate. Check `api-contract.md` and `implementation.md`
against `requirement.md` and `architecture-design.md`, then proceed to phase 4 TDD.
Default human review happens once, after phase 4 implementation and verification,
and before phase 5 closeout. Record the reviewed code/artifact revisions, evidence, and decision
in `implementation.md`; do not request the same approval again while the
same implementation and contract remain unchanged.

This is a substantive implementation-correctness review, not a line-by-line
style review or a long accumulation of tiny partial fixes. Judge only:
- Overall direction against requirements.
- Implementation completeness and behavioral correctness of actual code against acceptance criteria.
- Architecture/domain boundaries and structural defects.
- Data, security, and operational risks.
- Missing critical tests.

Inspect actual code, tests, and runtime evidence alongside requirements and design;
planned tests or an implementation specification alone cannot prove correctness.
Return a concise `PASS` or `BLOCKED` verdict with
only BLOCKER/HIGH findings and evidence (code/artifact/section or test/runtime result).
Use these severities; `partial` is not a default human-review progress state:
| Severity | Meaning and disposition |
|---|---|
| BLOCKER | Critical correctness/safety failure or unusable contract; blocks |
| HIGH | Material requirement, completeness, boundary, risk, or critical-test defect; blocks |
| MEDIUM | Bounded non-blocking concern; track in the owning artifact only if it affects correctness or risk |
| NIT | Non-blocking style/convention preference; omit from the human-review action list |

Do not record or repeatedly fix line wrapping, formatting, naming nitpicks,
ordinary code convention, or other non-blocking partial improvements in human
review. Route them to formatter/linter/CI or ignore them. A non-blocking nit
must not create another human review cycle or reopen PASS. MEDIUM tracking alone
does not request another review; material impact must meet BLOCKER/HIGH criteria.

Reopening this review is risk-triggered only: new irreversible, high-cost,
high-risk, cross-team, API compatibility, security, or data migration changes;
explicit contract or architecture change; unresolved substantive review objection;
or failed quality gate exposing a BLOCKER/HIGH defect in the reviewed work.
A nit alone is not a failed quality gate. Record the trigger and affected scope;
fix and verify affected work before returning it to the same review boundary.
Pre-coding check failures require correction, not a human approval gate.
Automated tests and agent reviews still run; one human review never converts a
failed check into PASS or bypasses an unresolved objection.

### Conditional ADR

ADR is conditional, not a default artifact: create one only for durable or
irreversible, costly, cross-team, high-risk, externally breaking, or contested
decisions. Routine reversible choices stay in the owning artifact. Preserve the
existing `ADR-NNNN` IDs, registry, lifecycle, and supersession rules;
`architecture-design.md` references ADR IDs instead of duplicating full ADR content.
For this distribution repo, `docs/maintenance/adr-policy.md` owns ADR operations;
consumer projects retain their existing ADR system and paths.

### Minimal durable documents and conditional handoff

Keep `requirement.md`, `architecture-design.md`, `api-contract.md`,
`implementation.md`, qualifying ADRs, `retro.md`, and `report.md` as the minimal
durable set. Handoff is conditional: create `handoff.md` only for session
interruption, explicit pause/resume, long-running unfinished work, ownership
transfer, or a blocker requiring another session. Link existing owners rather
than copying their content; routine closeout uses `report.md`.
For new work, `review.md`, `handoff.md`, `daily-handoff.md`, and derived `.html`
must not be required or automatically generated for every task.

### Legacy compatibility and deprecation

The old 7-step/Gate presentation is deprecated as the required human workflow
for new work. Existing commands remain supported: `sfs start`, `sfs brainstorm`,
`sfs plan`, `sfs implement`, `sfs review --gate 3`, `sfs review --gate 6`,
`sfs retro`, and `sfs report`. Gate 1–7 labels, internal gate IDs, tests,
`.sfs-local/current-sprint`, `events.jsonl`, and existing consumer workbenches
remain compatible. Do not rename, reset, migrate, or fabricate their state.

This slice changes authoring policy, not runtime dispatch or artifact generation.
Legacy `brainstorm.md`, `plan.md`, and `implement.md` remain valid runtime inputs;
`implementation.md` is not a drop-in filename rename of `implement.md`.
Keep required legacy fields/evidence and link canonical owners when present.
Legacy Gate 3/6 reviews still run on existing rails; their agent/automated/runtime
evidence is distinct from the single substantive human review. Existing runtime
daily-handoff generation remains compatible, not a requirement for every new task.
Gate 3 pre-coding checks do not require human approval; Gate 6 evidence does not replace
the human review after phase 4 and before phase 5.

For new work, `review.md` and `handoff.md` are not required authored artifacts:
keep the post-implementation human-review decision in `implementation.md` and useful handoff
context in `report.md`; create a separate handoff only on the triggers above.
Existing `review.md`, `handoff.md`, `daily-handoff.md`/`.html` remain readable and
compatible for legacy work. Do not delete existing user workbench data in this slice.
Runtime scaffolding, validators, and projections need a separate compatible
slice before the CLI can emit and consume only the new canonical artifact set.
Future cleanup: obsolete transient docs may be archived or removed only after
confirming they are not referenced by active state/tests and preserving required
historical evidence. This retention rule does not authorize cleanup in this slice.

## Keep / Shrink / Remove

- Keep a step when it prevents security, data-loss, public-contract, regression,
  release, or user-judgment failures that tests cannot cheaply cover.
- Shrink a step when it is valuable but can be an auto-lens, checklist row,
  template field, or post-run assertion instead of a user-visible ritual.
- Remove or downgrade a step when it is only ceremony, duplicates stronger
  evidence, asks the user for runnable work, or repeatedly blocks mainline work.
- Never remove the invariant. Refactor the evidence path: automate, narrow,
  merge with an adjacent gate, or require a waiver.

## Bottleneck Ledger

Record only meaningful signals:

- user-call count, runnable-step delegation count, review loop count;
- time spent blocked by auth/tool setup versus main objective;
- repeated finding category and whether a guard/test can catch it earlier;
- token/context growth, stale artifacts, and manual copy-paste handoffs;
- command/test/runtime wait that can become parallel, cached, or targeted.

## Refactor Rule

The output should be less ceremony and equal or stronger quality:

- fewer manual prompts or repeated reviews;
- clearer trigger conditions and smaller context load;
- same or stronger automated test, smoke, ledger, or release verifier evidence;
- no reduction in security, data validation, DDD/TDD, or user approval safety.

## Process self-audit

At each gate, review loop, recurring checklist, or ceremony, ask: Does this gate or ceremony still serve the current objective and prevent a real failure?

- If yes, keep the invariant and make the evidence cheaper where possible.
- If partly, shrink it into an auto-lens, template row, or post-run assertion.
- If no, remove, downgrade, defer, or require an explicit waiver instead of
  preserving ceremony.

## Anti-yak cadence

Use anti-yak cadence as a recommendation, not a hard blocker: after 3 meta-system WUs, schedule at least 1 user-outcome WU or record a waiver with the
owner reason. A user-outcome WU advances a real product/user result outside the
SFS method itself; a meta-system WU changes SFS process, policy, templates,
review rails, or instrumentation.
