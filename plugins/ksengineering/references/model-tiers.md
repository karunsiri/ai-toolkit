# Model tiers

Shared by every skill in this plugin. Skills name a **tier** per step, never a model. This file is the only place that maps tiers to models. The goal: spend strong models only where judgment matters.

## Tiers

| Tier | Use for | Effort |
|------|---------|--------|
| **deep** | Framing a plan, design forks, root-causing a hard bug, reviewing a risky change | high |
| **standard** | Writing code and config, fixing review comments, writing tests | medium |
| **light** | Code/file/text search, fetching PR data, polling CI, README/docs edits, mechanical renames | low |

Rule of thumb: if a wrong answer is cheap to spot and redo, it is **light**. If it ships to prod or decides the shape of the work, it is **deep**. Everything else is **standard**.

## Matrix

| Tier | Claude Code | Cursor | Codex |
|------|-------------|--------|-------|
| deep | `opus`, effort `high` | parent model (`inherit`); pick a strong model in the selector, e.g. `claude-opus-5[effort=high]` | strongest model, `model_reasoning_effort=high` |
| standard | `sonnet`, effort `medium` | `inherit` | default coding model, `model_reasoning_effort=medium` |
| light | `haiku`, effort `low` | `inherit`; pick a fast model in the selector when you run it by hand | small/fast model (e.g. a `-mini` or `-spark` variant), `model_reasoning_effort=low` |

Model names are examples, not pins. If one is unavailable, fall to the nearest tier: cheapest available for **light**, most capable available for **deep**.

## How each tool runs a tier

**Claude Code.** Spawn the plugin agent for the tier. Its model and effort live in its frontmatter (`agents/`).

| Tier | Agent | Example |
|------|-------|---------|
| light | `ksengineering:ks-scout` (read-only) | "Use ks-scout to find every caller of `TokenTTL`; return `file:line` only." |
| light edit | `ksengineering:ks-builder` spawned with model `haiku`, effort `low`; or inline in the session when it is a few lines | "Use ks-builder (haiku, low) to update the README install section to match `plugin.json`." |
| standard | `ksengineering:ks-builder` | "Use ks-builder to apply fix 1 and 2, run `bundle exec rspec spec/auth`, report the diff." |
| deep | `ksengineering:ks-thinker` | Only when offered and accepted (see **Session floor**). |

**Cursor.** The plugin ships the same roles in `agents-cursor/` with `model: inherit`, so they run on your current model. You still get the role split and a separate context, which keeps search output out of the main thread. To also save on model cost, switch to a fast model before a light pass. Example: "Use ks-scout to list files that read `/etc/letsencrypt`." with a fast model selected.

**Codex.** Plugins cannot ship custom agents, so run each tier as its own pass. Keep light passes small and return compact output (paths, counts, one-line findings) so the main pass stays small. Examples:

```bash
codex -c model_reasoning_effort=low "List every file under app/ that calls TokenTTL. Output file:line only."
```

```bash
codex -c model_reasoning_effort=high "Root-cause the failing spec in spec/auth/token_spec.rb. Evidence first."
```

In an interactive session, switch with `/model` before the pass. If you have custom agents in `~/.codex/agents/`, you can name one for the pass ("Have explorer map the callers"); the plugin does not install them.

## Session floor

**Deep** steps run in the main session, not a subagent: a fresh agent would re-read everything the session already knows. If the session model is below the deep tier (e.g. Haiku, a `-mini` model, or effort `low`), warn once before a deep step and suggest switching (`/model` in Claude Code and Codex, the model selector in Cursor). If the problem looks hard (several failed hypotheses, a design fork with no clear winner, security or data at stake), also offer to hand that step to `ks-thinker`. Never switch on your own.

## Verification

Match verification to risk. Most work needs none beyond the executor's own checks.

| Change | Verification |
|--------|--------------|
| light (search, docs, renames) | none |
| standard | the executor runs its checks; the main session reads the diff |
| risky (security, permissions, data, prod config, money) | one separate check at **standard** tier, high effort, with a short brief: 2-3 named risks, reuse the executor's tests |
| anything, on request | a **deep** verifier, only when the user asks |

Do not give a verifier an open-ended checklist or ask it to build its own test harness unless the user asks. That is where most of the cost goes.
