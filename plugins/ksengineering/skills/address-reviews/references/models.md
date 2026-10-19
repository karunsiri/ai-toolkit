# Model selection

Tiers, model names and per-tool mechanics live in the shared [model tiers](model-tiers.md). This file only maps this skill's roles and flags onto those tiers.

## Roles

| Role | Tier | Claude Code | Cursor | Codex |
|------|------|-------------|--------|-------|
| Fetcher | light | `ks-scout` | `ks-scout` (`inherit`) | low-effort pass |
| Poller | light | `ks-scout` | `ks-scout` (`inherit`) | low-effort pass |
| Thinker | standard (default) | `ks-builder` | `ks-builder` (`inherit`) | session model, `model_reasoning_effort=medium` |
| Thinker, `--high` | deep | `ks-thinker` | `ks-thinker` (`inherit`); pick a strong model | strongest model, `model_reasoning_effort=high` |
| Thinker, `--xhigh` | deep, max | `ks-thinker`, spawned with effort `max` | `ks-thinker` (`inherit`); pick the strongest model | strongest model, `model_reasoning_effort=xhigh` (else `high`) |

Raising effort never moves the fetcher or poller off the light tier.

## Thinker floor

The thinker classifies comments and writes fixes, so it must not run on the light tier. On Claude Code it runs as `ks-builder` or `ks-thinker`, so it never inherits a small session model. On Cursor (`inherit`) and Codex (session pass) it does. There, if the session model is a fast/small one (Haiku, a `-mini` model, effort `low`) and no effort flag raises it, warn and confirm before proceeding. Options: run anyway as a fast, lower-confidence pass; re-run with `--high` / `--xhigh`; or switch the session model. Unattended, proceed low-confidence: auto-apply only unambiguous must-fix and list the rest.

## Claude Code notes

Spawn each role as its own agent so fetcher and poller output stays out of the thinker's context. That isolation is where most of the savings come from. For step 8, prefer the PR activity subscription over an active poll loop.
