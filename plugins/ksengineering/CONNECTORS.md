# Connectors

## How tool references work

Plugin files use `~~category` as a placeholder for whatever tool the user connects in that category. For example, `~~source control` might mean GitHub, GitLab, or any other VCS with an MCP server.

Plugins are **tool-agnostic** — they describe workflows in terms of categories rather than specific products. The `.mcp.json` pre-configures specific MCP servers, but any MCP server in that category works.

## Connectors for this plugin

| Category | Placeholder | Included servers | Other options |
|----------|-------------|-----------------|---------------|
| Source control | `~~source control` | GitHub | GitLab, Bitbucket |
| Project tracker | `~~project tracker` | Linear, Atlassian (Jira/Confluence) | Shortcut, ClickUp |
| Monitoring | `~~monitoring` | Datadog | New Relic, Grafana, Splunk |
| Incident management | `~~incident management` | PagerDuty | Opsgenie, Incident.io |
| CI/CD | `~~CI/CD` | — | CircleCI, GitHub Actions, Jenkins |
