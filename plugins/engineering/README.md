# Engineering Plugin

Custom engineering plugin for DevOps, Ruby, systems, cloud-native, and web app work. Covers debugging, code review, architecture decisions, incident response, and technical documentation. Works standalone or with connected tools.

## Commands

| Command | Description |
|---|---|
| `/debug` | Structured debugging session — reproduce, isolate, diagnose, and fix |

## Skills

Domain knowledge Claude uses automatically when relevant:

| Skill | Description |
|---|---|
| `debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |

## Example Workflows

### Debug a problem

```
/debug Users are getting 500 errors on checkout
```

Walk through a structured debugging process: clarify expected vs actual, capture reproduction steps, isolate the fail path, form ranked hypotheses, fix.

## Standalone + Supercharged

Every command works without integrations — paste errors, describe the system, share logs. Connect tools for richer context:

| What You Can Do | Standalone | Supercharged With |
|-----------------|------------|-------------------|
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
