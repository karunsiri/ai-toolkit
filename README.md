# ai-toolkit

Plugins for personal engineering productivity — compatible with Claude Code, Cursor, and Codex. Covers session continuity and structured engineering workflows across DevOps, Ruby, systems, cloud-native, and web app work.

## Installation

### Claude Code

#### From GitHub (without cloning)

```bash
claude plugin marketplace add karunsiri/ai-toolkit

# Install plugins
claude plugin install engineering@karunsiri-ai-toolkit
claude plugin install productivity@karunsiri-ai-toolkit
```

#### From cloned source

```bash
git clone https://github.com/karunsiri/ai-toolkit.git
claude plugin marketplace add ./ai-toolkit

# Install plugins
claude plugin install engineering@karunsiri-ai-toolkit
claude plugin install productivity@karunsiri-ai-toolkit
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
ln -s "$(pwd)/ai-toolkit/plugins/engineering" ~/.cursor/plugins/local/engineering
ln -s "$(pwd)/ai-toolkit/plugins/productivity" ~/.cursor/plugins/local/productivity
```

Then verify in Cursor: Settings → Plugins → confirm both plugins appear.

### Codex

Codex compatibility currently starts with the Productivity plugin.

```bash
git clone https://github.com/karunsiri/ai-toolkit.git
cd ai-toolkit

codex plugin marketplace add .
codex plugin add productivity@ai-toolkit
```

Start a new Codex conversation after installation. Invoke the skill explicitly with `$session-handoff`, or ask to create, load, or check a project handoff.

## Plugins

### [engineering](plugins/engineering)

Structured engineering workflows — debugging, code review, architecture decisions, incident response, and technical documentation.

| Command | Description |
|---|---|
| `/dbg` | Reproduce, isolate, diagnose, and fix bugs across any stack |

Works standalone or with connected tools (GitHub, Linear, Datadog, PagerDuty).

```bash
claude plugin install engineering@karunsiri-ai-toolkit
```

### [Productivity](plugins/productivity)

Create and resume session handoff documents so a fresh agent can continue long-running work with zero ambiguity.

| Command | Description |
|---|---|
| `/session-handoff` | Create or resume a handoff document |

```bash
claude plugin install productivity@karunsiri-ai-toolkit
```

## Structure

```
.agents/
└── plugins/
    └── marketplace.json # Codex repository marketplace
plugins/
├── engineering/          # Engineering workflows
│   ├── .claude-plugin/
│   │   └── plugin.json   # Claude Code manifest
│   ├── .cursor-plugin/
│   │   └── plugin.json   # Cursor manifest
│   ├── .mcp.json         # MCP servers (Claude Code)
│   ├── mcp.json          # MCP servers (Cursor)
│   ├── CONNECTORS.md
│   ├── README.md
│   └── skills/
│       └── dbg/
│           └── SKILL.md
└── productivity/         # Session continuity
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
