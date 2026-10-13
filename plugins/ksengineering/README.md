# Engineering Plugin

Custom engineering plugin for DevOps, Ruby, systems, cloud-native, and web app work. Covers planning, debugging, PR review handling, code review, architecture decisions, incident response, and technical documentation. Works standalone or with connected tools.

## Commands

| Command | Description |
|---|---|
| `/planning` | Risk-first phased implementation plan — frame, surface unknowns, phase the work, emit plan + tasks |
| `/debug` | Structured debugging session — reproduce, isolate, diagnose, and fix |
| `/address-reviews` | Agentic loop that addresses PR review feedback — fetch, classify, summarize, fix, reply in-thread, re-request bot review, watch bot CI, repeat |

## Skills

Domain knowledge Claude uses automatically when relevant:

| Skill | Description |
|---|---|
| `planning` | Plan engineering work in risk-first phases — walking skeleton first, spikes for unknowns, no estimates |
| `debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |
| `address-reviews` | Work a PR's review threads to zero — classify (must/should/optional/false-positive), fix, reply, resolve, re-request, watch bot CI |

## Example Workflows

### Plan a feature

```
/planning Add multi-currency support to checkout
```

Nails down goal, non-goals, success criteria, and constraints (won't proceed while any is vague), surfaces unknowns as timeboxed spikes, orders phases risk-first starting with a walking skeleton, maps parallel tracks, and emits a living `plan.md` plus a rolling-wave `tasks.md`.

### Debug a problem

```
/debug Users are getting 500 errors on checkout
```

Walk through a structured debugging process: clarify expected vs actual, capture reproduction steps, isolate the fail path, form ranked hypotheses, fix.

### Address PR review feedback

```
/address-reviews --high --bot-only --resolve
```

Fetches open review threads on the light tier, classifies each into must-fix / should-fix / optional / false-positive, shows a colored summary before touching code, applies fixes on the standard tier (deep with `--high`/`--xhigh`), replies in-thread (mentioning the commenter when there is no thread), resolves the threads it fixed, re-requests bot review, watches bot CI for new comments, and loops until clean. Flags: `--high`/`--xhigh` move the thinker to the deep tier, `--bot-only` limits scope to bots/scanners, `--resolve` closes addressed threads.

## Model Tiers

Each skill step runs on a tier instead of the session model, to cut token use. Tiers, models and per-tool behavior are defined once in [references/model-tiers.md](references/model-tiers.md).

| Tier | Used for | Claude Code agent |
|---|---|---|
| deep | planning, diagnosis, hard design calls | main session; `ks-thinker` (opus, high) when offered |
| standard | code, config, tests, review fixes | `ks-builder` (sonnet, medium) |
| light | search, fetch, poll, docs edits | `ks-scout` (haiku, low, read-only) |

- **Claude Code**: agents in `agents/` set their own model and effort.
- **Cursor**: the same agents in `agents-cursor/` with `model: inherit`. You get the role split and separate context; pick a fast model by hand for light passes.
- **Codex**: plugins cannot ship agents, so skills give text guidance (`codex -c model_reasoning_effort=low ...`).

Verification follows risk: none for light work, the executor's own checks for standard work, and a separate short check only for risky changes (security, permissions, data, prod config).

Cursor and Codex behavior is from their docs and not yet tested.

## Standalone + Supercharged

Every command works without integrations — paste errors, describe the system, share logs. Connect tools for richer context:

| What You Can Do | Standalone | Supercharged With |
|-----------------|------------|-------------------|
| Planning | Describe the work | Project tracker (create milestones + tickets) |
| Debug sessions | Describe the problem | Monitoring (pull logs and metrics) |
| Address reviews | Paste review comments | Source control (fetch threads, reply, resolve, re-request), CI/CD (watch bot runs) |
| Code review | Paste diff or code | Source control (pull PRs automatically) |
| Incident response | Describe the incident | Monitoring, Incident management |

## MCP Integrations

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](CONNECTORS.md).

| Category | Examples | What It Enables |
|---|---|---|
| **Source control** | GitHub, GitLab | PR diffs, commit history, branch status |
| **Project tracker** | Linear, Jira | Ticket status, sprint data |
| **Monitoring** | Datadog, New Relic | Logs, metrics, alerts |
| **Incident management** | PagerDuty | On-call schedules, incident tracking |
