# Connectors

## How tool references work

Plugin files use `~~category` as a placeholder for whatever tool the user connects in that category. For example, `~~source control` might mean GitHub, GitLab, or any other VCS with an MCP server.

Plugins are **tool-agnostic** — they describe workflows in terms of categories rather than specific products. No MCP servers are bundled. Any MCP server in a category works.

## Connectors for this plugin

| Category | Placeholder | Examples |
|----------|-------------|----------|
| Source control | `~~source control` | GitHub, GitLab, Bitbucket |
| Project tracker | `~~project tracker` | Linear, Atlassian (Jira), Shortcut, ClickUp |
| Monitoring | `~~monitoring` | Datadog, New Relic, Grafana, Splunk |
| Incident management | `~~incident management` | PagerDuty, Opsgenie, Incident.io |
| CI/CD | `~~CI/CD` | CircleCI, GitHub Actions, Jenkins |
