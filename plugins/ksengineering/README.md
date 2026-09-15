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

Fetches open review threads with a cheap model, classifies each into must-fix / should-fix / optional / false-positive, shows a colored summary before touching code, applies fixes with the effort-selected model, replies in-thread (mentioning the commenter when there is no thread), resolves the threads it fixed, re-requests bot review, watches bot CI for new comments, and loops until clean. Flags: `--high`/`--xhigh` set thinker effort, `--bot-only` limits scope to bots/scanners, `--resolve` closes addressed threads.

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
