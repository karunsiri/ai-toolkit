---
name: planning
description: Plan a piece of engineering work like a senior engineer — risk-first, in phases, with prerequisites folded in and unknowns killed early. Trigger with "/planning", "plan this feature", "break this down", "roadmap for", "plan the migration/refactor", or when someone needs a phased implementation plan. Do NOT trigger on vague design questions like "how should we approach this?" — that is a discussion, not a plan request.
argument-hint: "<what you want to build, migrate, or refactor>"
---

# /planning

Produce a phased, risk-first implementation plan — the way a senior engineer plans, not the way an AI dumps a flat task list. Scary and uncertain work goes first. Prerequisites are folded into the risk order, not bolted on. Later phases stay coarse until you know enough to sharpen them.

Five steps, strict order. No plan before the frame is nailed down. No phase without a verifiable exit.

## Usage

```
/planning $ARGUMENTS
```

## What I Need From You

I will not write a plan on vague input. Before phasing anything, I need — and will interrogate you until I have — all four:

- **Goal** — the outcome, in one sentence. What is true when this is done?
- **Non-goals / scope boundary** — what this explicitly does *not* cover. This is where scope creep dies.
- **Success criteria** — how we know it worked. Observable, not "it feels done".
- **Hard constraints** — deadline, stack, team size, compliance, systems that can't change.

Helpful but optional: existing code or architecture context, who consumes the result, prior attempts.

If you can't answer the four, we're not ready to plan — we're ready to *discuss*, which is a different thing.

## Steps

### 1. Frame

Pin the four inputs above. Refuse to proceed while any is missing — restate what you have, name what's missing, ask for it.

Then **detect the work type**, because they phase differently:

- **Feature (greenfield)** — walking skeleton first, then flesh out.
- **Migration** — strangler-fig: run old and new in parallel, cut over incrementally, keep a rollback path per slice. Never a big-bang switch.
- **Refactor** — hold behavior constant; lean on characterization tests before touching structure; small reversible steps.
- **Spike-heavy / R&D** — the plan *is* mostly spikes until the unknowns resolve; don't pretend to phase past them.

State the detected type and the phasing pattern it implies.

### 2. Surface Unknowns & Prerequisites

Before drawing phases, list what could blow up the plan:

- **Open questions & blocking decisions** — anything unresolved that changes the shape of the work.
- **Prerequisites** — access, credentials, environments, tooling, data, external-team asks.
- **Genuine unknowns** — perf viability, an unproven API, a hard integration.

For each genuine unknown, propose a **timeboxed throwaway spike**: the *question* it answers, the *timebox*, and the *decision it feeds*. Spike code is disposable — its output is a decision, not a feature.

For **design forks** (e.g. Postgres vs DynamoDB), judge by stakes:
- **Reversible / cheap** → decide inline with a one-line rationale, mark it revisitable.
- **One-way-door / expensive** → hand off if a `/architecture` (ADR) or `/system-design` skill is available; otherwise capture it inline as a pending decision with the trade-off named. Don't reimplement deep architecture work here.

**Prerequisites are not a separate gate.** Risky or slow ones (external-team dependency, unproven infra) *lead* Phase 1. Trivial ones (install a library) sit inline in the phase that needs them.

### 3. Phase the Work — Risk-First

**Phase 1 is a walking skeleton**: the thinnest end-to-end slice that touches every major component, running for real. It proves the architecture and integration before any polish. The riskiest, most-uncertain work comes earliest — de-risk over time, don't leave the scary part for the end.

Each phase carries:
- **Entry prerequisites** — what must be true to start it.
- **Exit criteria** — a *verifiable* check: a passing test, a runnable demo, a command that returns X. Not "looks done".
- **Demoable output** — something real you can show or ship.

**Elaborate in rolling waves.** The current and next phase get sharp detail. Later phases stay as coarse one-liners — you can't honestly decompose Phase 5 before Phase 1's spike tells you whether Phase 5 still exists. Detail gets filled in as each wave approaches.

**No estimates.** No hours, no days, no story points. Sequence, dependencies, and exit criteria carry the plan. Task granularity conveys proportion (see step 5).

### 4. Dependency & Sequence Map

Lay out what blocks what. Mark **parallel tracks** explicitly — work that can run concurrently vs. strict blockers — so real concurrency is visible and bottlenecks surface early.

### 5. Emit Artifacts

Write two files into a per-plan directory, slug from the goal (e.g. `checkout-redesign-2026-09-10`):

- **`.agents/plans/{slug}/plan.md`** — the living plan (format below). Rewrite the body as reality shifts; log *why* in the decision log at the bottom.
- **`.agents/plans/{slug}/tasks.md`** — two-tier task list, rolling-wave: near-term phases have **atomic, independently verifiable** tasks (~one PR each); far-term phases stay coarse until their wave arrives.

These are the handoff — another session or teammate executes from them.

## Plan Artifact

`.agents/plans/{slug}/plan.md`:

```markdown
# Plan: {goal in one line}

## Frame
- **Goal**: [outcome]
- **Non-goals**: [explicitly out of scope]
- **Success criteria**: [observable]
- **Constraints**: [deadline, stack, team, compliance]
- **Work type**: feature | migration | refactor | spike-heavy

## Unknowns & Prerequisites
- **Open questions**: [...]
- **Prerequisites**: [access, env, tooling, external asks]
- **Spikes**:
  | Spike | Question | Timebox | Feeds decision |
  |-------|----------|---------|----------------|
  | ... | ... | ... | ... |
- **Pending design decisions**: [fork — deferred to ADR / decided inline]

## Phases (risk-first)

### Phase 1 — {name} (walking skeleton)
- **Entry**: [prereqs]
- **Work**: [what happens]
- **Exit**: [verifiable check]
- **Demo**: [what you can show]

### Phase 2 — {name}
...

### Phase N — {name}  (coarse until its wave)
- one-line intent

## Dependency Map
- Phase 1 → Phase 2 (blocks)
- Phase 2 ∥ Phase 3 (parallel)
- ...

## Decision Log
| Date | Change | Why |
|------|--------|-----|
| ... | ... | ... |
```

`.agents/plans/{slug}/tasks.md`:

```markdown
# Tasks: {goal}

## Phase 1 — {name}   (current wave — atomic)
- [ ] [one clear outcome, ~1 PR, verifiable]
- [ ] ...

## Phase 2 — {name}   (next wave — atomic)
- [ ] ...

## Phase 3+ — later   (coarse — sharpen on arrival)
- [ ] [one-line intent]
```

Update the checkboxes and the decision log as work proceeds.

## Operating Rules

- Do not produce a plan before goal, non-goals, success criteria, and constraints are all pinned. Missing one → interrogate, don't guess.
- Do not phase past a genuine unknown without proposing a spike to resolve it.
- Every phase must have a verifiable exit criterion. If you can't state the check, the phase isn't defined yet.
- Never emit time or effort estimates.
- Don't fully decompose later phases — rolling waves only. Detail follows knowledge.
- Prerequisites fold into the risk order; risky/slow ones lead, trivial ones inline. No standalone "Phase 0" unless a prereq genuinely blocks everything.
- Stay in lane: deep architecture, test tactics, and ship gating belong to other skills (see below). Orchestrate them; don't reimplement them.

## Related Skills

Delegate only when the skill is actually present in this session:

- **`/architecture` or `/system-design`** — for one-way-door design forks. If present, hand the decision off. If not, capture it inline as a pending decision with the trade-off named.
- **`/testing-strategy`** — for how to verify a phase. If present, name what to verify and let it design the tests. If not, state the verifiable check directly in the exit criteria.
- **`/deploy-checklist`** — for the final ship phase's gating. If present, point the last phase at it. If not, list the ship checks inline.

## If Connectors Available

If **~~project tracker** is connected:
- Offer to create the phases as milestones/epics and the atomic tasks as tickets, preserving the dependency links.
- Pull existing tickets that overlap so the plan doesn't duplicate planned work.

If **~~source control** is connected:
- Check recent commits and open PRs touching the affected area to ground the plan in the current state.
- Map phases to branches/PRs where it clarifies the sequence.

## Tips

1. **Bring the four inputs** — goal, non-goals, success criteria, constraints. Vague in, vague out.
2. **Name your unknowns** — the thing you're least sure about should lead the plan, not hide at the end.
3. **Say the work type** if you know it — "this is a migration", "this is a refactor" — it changes the whole phasing shape.
