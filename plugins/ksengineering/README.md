# Engineering Plugin

Custom engineering plugin for DevOps, Ruby, systems, cloud-native, and web app work. Covers planning, debugging, code review, architecture decisions, incident response, and technical documentation. Works standalone or with connected tools.

## Commands

| Command | Description |
|---|---|
| `/planning` | Risk-first phased implementation plan — frame, surface unknowns, phase the work, emit plan + tasks |
| `/debug` | Structured debugging session — reproduce, isolate, diagnose, and fix |

## Skills

Domain knowledge Claude uses automatically when relevant:

| Skill | Description |
|---|---|
| `planning` | Plan engineering work in risk-first phases — walking skeleton first, spikes for unknowns, no estimates |
| `debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |

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

## Standalone + Supercharged

Every command works without integrations — paste errors, describe the system, share logs. Connect tools for richer context:

| What You Can Do | Standalone | Supercharged With |
|-----------------|------------|-------------------|
| Planning | Describe the work | Project tracker (create milestones + tickets) |
| Debug sessions | Describe the problem | Monitoring (pull logs and metrics) |
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
