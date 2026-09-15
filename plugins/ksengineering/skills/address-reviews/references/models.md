# Model selection

Which model each role runs on, per tool. The goal: cheap and fast for fetch and poll (they only shuttle structured data), your best judgment for the thinker (it reads code and writes it).

The **thinker** uses its configured model if one is set, otherwise the current session model. The effort flags override that with a stronger model and more reasoning:

- no flag → configured model, else session model
- `--high` → stronger model, high reasoning
- `--xhigh` → strongest available, max reasoning (falls back to `--high` if a tool has no higher tier)

The **fetcher** and **poller** always take the cheapest, fastest model available regardless of effort — raising effort never raises their model.

## Matrix

| Role | Claude Code | Codex | Cursor |
|------|-------------|-------|--------|
| Fetcher | Haiku (`claude-haiku-4-5`) | `gpt-5-mini` (or `gpt-5-codex-mini`), reasoning low | fast tier (Haiku / `gpt-5-mini`) |
| Poller | Haiku (`claude-haiku-4-5`) | `gpt-5-mini`, reasoning low | fast tier (Haiku / `gpt-5-mini`) |
| Thinker (default) | session model (Sonnet, `claude-sonnet-5`) | `gpt-5-codex`, reasoning medium | Cursor Auto / Sonnet |
| Thinker (`--high`) | Opus (`claude-opus-5`), think hard | `gpt-5-codex`, reasoning high | Opus / GPT-5, high |
| Thinker (`--xhigh`) | Opus (`claude-opus-5`), ultrathink | `gpt-5-codex`, reasoning xhigh (else high) | Opus / GPT-5, max reasoning |

Model IDs are current examples, not pins. If an ID is unavailable in the running tool, fall to the nearest tier: cheapest-available for fetcher/poller, most-capable-available for the thinker.

## How each tool runs the roles

**Claude Code** — spawn each role as a subagent (Task tool) with the `model` set from the matrix. Real subagents keep the fetcher/poller output out of the thinker's context, which is where the token savings come from. Map effort to reasoning with the usual keywords (`think hard` for `--high`, `ultrathink` for `--xhigh`). For step 8, prefer the PR activity subscription over an active poll loop.

**Codex** — Codex has no separate subagent spawn today, so run each role as a distinct pass in the loop. Keep fetch and poll passes on the cheap model (switch with `-c model=` / `-c model_reasoning_effort=` or the session config) and return compact structured output so the thinker pass stays small. If `xhigh` is not accepted, use `high`.

**Cursor** — no programmatic subagents today; run the roles as separate passes and pick the model per pass from Cursor's model selector. Use a fast tier for fetch/poll, a strong tier for the thinker.

## Configuring a default thinker model

If you want the thinker to default to something other than the session model, set it in the tool's own model config (Claude Code subagent model, Codex `model` config, Cursor model selector) before invoking the skill. The effort flags still override it for that run.
