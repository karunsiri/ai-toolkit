# ai-toolkit

Claude Code plugins for personal engineering productivity. Covers session continuity and structured engineering workflows across DevOps, Ruby, systems, cloud-native, and web app work.

## Installation

### From GitHub (without cloning)

```bash
claude plugin marketplace add karunsiri/ai-toolkit

# Install plugins
claude plugin install engineering@karunsiri-ai-toolkit
claude plugin install session-handoff@karunsiri-ai-toolkit
```

### From cloned source

```bash
git clone https://github.com/karunsiri/ai-toolkit.git
claude plugin marketplace add ./ai-toolkit

# Install plugins
claude plugin install engineering@karunsiri-ai-toolkit
claude plugin install session-handoff@karunsiri-ai-toolkit
```

Scope options: `--scope user` (default), `--scope project` (shared with team), `--scope local` (gitignored).

## Plugins

### [engineering](plugins/engineering)

Structured engineering workflows — debugging, code review, architecture decisions, incident response, and technical documentation.

| Command | Description |
|---|---|
| `/debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |

Works standalone or with connected tools (GitHub, Linear, Datadog, PagerDuty).

```bash
claude plugin install engineering@karunsiri-ai-toolkit
```

### [session-handoff](plugins/session-handoff)

Create and resume session handoff documents so a fresh agent can continue long-running work with zero ambiguity.

| Command | Description |
|---|---|
| `/session-handoff` | Create or resume a handoff document |

```bash
claude plugin install session-handoff@karunsiri-ai-toolkit
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
