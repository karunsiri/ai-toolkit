# ai-toolkit

Plugins for personal engineering productivity — compatible with Claude Code, Cursor, and Codex. Covers session continuity and structured engineering workflows across DevOps, Ruby, systems, cloud-native, and web app work.

## Installation

### Claude Code

#### From GitHub (without cloning)

```bash
claude plugin marketplace add karunsiri/ai-toolkit

# Install plugins
claude plugin install ksengineering@karunsiri-ai-toolkit
claude plugin install ksproductivity@karunsiri-ai-toolkit
```

#### From cloned source

```bash
git clone https://github.com/karunsiri/ai-toolkit.git
claude plugin marketplace add ./ai-toolkit

# Install plugins
claude plugin install ksengineering@karunsiri-ai-toolkit
claude plugin install ksproductivity@karunsiri-ai-toolkit
```

Scope options: `--scope user` (default), `--scope project` (shared with team), `--scope local` (gitignored).

### Cursor

#### From Cursor Marketplace

Search `karunsiri-ai-toolkit` in Cursor Settings → Plugins.

#### From cloned source

```bash
git clone https://github.com/karunsiri/ai-toolkit.git

# Symlink plugins into Cursor's local plugin directory
mkdir -p ~/.cursor/plugins/local
ln -s "$(pwd)/ai-toolkit/plugins/ksengineering" ~/.cursor/plugins/local/ksengineering
ln -s "$(pwd)/ai-toolkit/plugins/ksproductivity" ~/.cursor/plugins/local/ksproductivity
```

Then verify in Cursor: Settings → Plugins → confirm both plugins appear.

### Codex

```bash
git clone https://github.com/karunsiri/ai-toolkit.git
cd ai-toolkit

codex plugin marketplace add .
codex plugin add ksengineering@ai-toolkit
codex plugin add ksproductivity@ai-toolkit
```

Start a new Codex conversation after installation. Invoke a skill explicitly (`$debug`, `$planning`, `$session-handoff`), or ask in plain language — e.g. debug an error, plan a feature, or create/load/check a project handoff.

## Plugins

### [ksengineering](plugins/ksengineering)

Structured engineering workflows — debugging, code review, architecture decisions, incident response, and technical documentation.

| Command | Description |
|---|---|
| `/planning` | Risk-first phased implementation plan — walking skeleton first, spikes for unknowns, no estimates |
| `/debug` | Reproduce, isolate, diagnose, and fix bugs across any stack |

Works standalone or with connected tools (GitHub, Linear, Datadog, PagerDuty).

```bash
claude plugin install ksengineering@karunsiri-ai-toolkit
```

### [Productivity](plugins/ksproductivity)

Create and resume session handoff documents so a fresh agent can continue long-running work with zero ambiguity.

| Command | Description |
|---|---|
| `/session-handoff` | Create or resume a handoff document |

```bash
claude plugin install ksproductivity@karunsiri-ai-toolkit
```

## Structure

```
.agents/
└── plugins/
    └── marketplace.json # Codex repository marketplace
plugins/
├── ksengineering/        # Engineering workflows
│   ├── .codex-plugin/
│   │   └── plugin.json   # Codex manifest
│   ├── .claude-plugin/
│   │   └── plugin.json   # Claude Code manifest
│   ├── .cursor-plugin/
│   │   └── plugin.json   # Cursor manifest
│   ├── .mcp.json         # MCP servers (Claude Code)
│   ├── mcp.json          # MCP servers (Cursor)
│   ├── CONNECTORS.md
│   ├── README.md
│   └── skills/
│       ├── debug/
│       │   └── SKILL.md
│       └── planning/
│           └── SKILL.md
└── ksproductivity/       # Session continuity
    ├── .codex-plugin/
    │   └── plugin.json   # Codex manifest
    ├── .claude-plugin/
    │   └── plugin.json   # Claude Code manifest
    ├── .cursor-plugin/
    │   └── plugin.json   # Cursor manifest
    ├── .mcp.json         # MCP servers (Claude Code)
    ├── mcp.json          # MCP servers (Cursor)
    └── skills/
        └── session-handoff/
            ├── SKILL.md
            ├── references/
            └── scripts/
```

## License

MIT
