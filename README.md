# ai-toolkit

Claude Code plugins for personal engineering productivity. Covers session continuity and structured engineering workflows across DevOps, Ruby, systems, cloud-native, and web app work.

## Plugins

### [engineering](plugins/engineering)

Structured engineering workflows — debugging, code review, architecture decisions, incident response, and technical documentation.

| Command | Description |
|---|---|
| `/debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |

Works standalone or with connected tools (GitHub, Linear, Datadog, PagerDuty).

```bash
claude plugins add karunsiri-ai-toolkit/engineering
```

### [session-handoff](plugins/session-handoff)

Create and resume session handoff documents so a fresh agent can continue long-running work with zero ambiguity.

| Command | Description |
|---|---|
| `/session-handoff` | Create or resume a handoff document |

```bash
claude plugins add karunsiri-ai-toolkit/session-handoff
```

## Structure

```
plugins/
├── engineering/          # Engineering workflows
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── .mcp.json         # MCP server configs
│   ├── CONNECTORS.md
│   ├── README.md
│   └── skills/
│       └── debug/
│           └── SKILL.md
└── session-handoff/      # Session continuity
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        └── session-handoff/
            ├── SKILL.md
            ├── references/
            └── scripts/
```

## License

MIT
