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

## Model Tiers

Tiers come from the shared [model tiers](../../references/model-tiers.md).

- **Planning itself is deep.** Framing, risk order, spikes and design forks run in the main session. If the session model is below the deep tier, ask the user at the start whether to switch, and wait for the answer before step 1 (see **Session floor** in the shared file). Do not continue silently. Do not switch on your own.
- **Grounding is light.** Looking up recent commits, open PRs, where a component lives, or what a config file holds goes to the light tier (`ks-scout`, or a low-effort pass on Codex). Keep only the compact answer.
- **Hard forks may go deeper.** If a design fork has no clear winner, or security or data is at stake, offer to hand that one question to `ks-thinker`. Ask first.
- **Tasks carry their tier.** Every near-term task in `tasks.md` gets a tier tag so whoever executes it knows what to spend (see step 5).

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

**Tag every near-term task** with one tier and, only when the risk calls for it, `[verify]`:

- `[light]` — search, inventory, docs/README, mechanical renames. No verifier.
- `[standard]` — code, config, tests. The executor runs its own checks; the session reads the diff.
- `[deep]` — a task that is itself a hard judgment (a design call, a tricky root cause). Rare: most deep work already happened while planning.
- `[verify]` — add only for risky changes: security, permissions, data, prod config, money. One separate check at the standard tier with 2-3 named risks; reuse the executor's tests.
- `[manual]` — steps only the user can do (deploys, merges, running playbooks against real hosts).

Pick the lowest tier that can do the task well. Do not add `[verify]` by default: most of a plan's cost goes into verifiers that find nothing.

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

## Execution
- Tiers (ksengineering model tiers): `[light]` search/docs, `[standard]` code/config, `[deep]` hard judgment
- `[verify]` only on risky tasks: [list which, and the 2-3 risks each]
- `[manual]` steps: [who runs them]

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
- [ ] `[light]` [inventory / search task, returns a list]
- [ ] `[standard]` [one clear outcome, ~1 PR, verifiable]
- [ ] `[standard][verify]` [risky change; risks: X, Y]
- [ ] `[manual]` [deploy / merge / run]

## Phase 2 — {name}   (next wave — atomic)
- [ ] `[standard]` ...

## Phase 3+ — later   (coarse — sharpen on arrival)
- [ ] [one-line intent]
```

Update the checkboxes and the decision log as work proceeds.

## Turn Summary

Long planning conversations lose track of `plan.md` and `tasks.md` under many turns of questions, decisions, and edits. Keep them visible:

- **Any turn that edits `plan.md` or `tasks.md`** — end the reply with a one-line pointer to both, as markdown links (they render as clickable file-preview links): `Plan files: [plan.md](.agents/plans/{slug}/plan.md), [tasks.md](.agents/plans/{slug}/tasks.md)`. The link target is the full path from the working directory, with the real `{slug}`. Never a bare filename like `(plan.md)`: it resolves to the working directory root and breaks.
- **No edit this turn, but 5+ turns since the last pointer** — emit the same line anyway. Long stretches of discussion without a file touch are exactly when the artifacts go missing from view.

Don't repeat this line every single turn if nothing changed and the last pointer was recent — that's noise, not signal.

## Operating Rules

- Do not produce a plan before goal, non-goals, success criteria, and constraints are all pinned. Missing one → interrogate, don't guess.
- Do not phase past a genuine unknown without proposing a spike to resolve it.
- Every phase must have a verifiable exit criterion. If you can't state the check, the phase isn't defined yet.
- Never emit time or effort estimates. (Tier tags are not estimates: they say which model to spend, not how long.)
- Every near-term task gets a tier tag. `[verify]` only on risky tasks, never by default.
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
