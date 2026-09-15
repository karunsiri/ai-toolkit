---
name: address-reviews
description: Agentic loop that works a pull request's review feedback to zero. Fetches open review threads and comments, classifies them (must-fix / should-fix / optional / false-positive), shows a colored summary before touching code, applies fixes, replies in-thread, optionally resolves, re-requests bot review, waits for the async re-review to finish, works its new comments, and repeats until the bot goes quiet. Trigger with "/address-reviews", "address the PR comments", "handle the review feedback", "fix the Copilot/CodeRabbit/ox-security comments", or when a PR has open review threads to work through. Do NOT trigger when the user wants to author a fresh review of someone else's PR.
argument-hint: "[--high|--xhigh] [--bot-only] [--resolve]"
---

# /address-reviews

Drive a pull request's review feedback to zero in a loop. Fetch, classify, show the summary, fix, reply, re-request, wait for the bot's next pass, repeat. Cheap models do the fetching and polling; the configured model does the thinking and the code.

Bot re-review is asynchronous: after a fix the bot takes a while to re-scan, and its comments appear only when that pass completes. The loop re-requests the bot, waits for the completion signal, addresses whatever comes back, and keeps going until the bot completes a pass with nothing new to say (or a loop guard trips, or the user stops it).

## Usage

```
/address-reviews [--high|--xhigh] [--bot-only] [--resolve]
```

| Flag | Meaning | Default |
|------|---------|---------|
| `--high` | Run the thinker at high effort (stronger model, more reasoning) | off |
| `--xhigh` | Run the thinker at max effort. Wins over `--high` if both given | off |
| `--bot-only` | Only address comments from bots/automated agents (Copilot, CodeRabbit, Dependabot, ox-security, Sonar, etc.). Skip human reviewers | off (all) |
| `--resolve` | Resolve a thread after its fix is pushed | off (leave open) |

No effort flag means the thinker uses its configured model, and if none is configured, the current session model. See [references/models.md](references/models.md) for the per-tool model matrix and how each effort maps to a model.

## Roles

Three roles, each on the cheapest model that can do its job. On Claude Code, spawn each as a subagent with the model below so context and cost stay isolated. On tools without subagents (Codex, Cursor today), run each role as a focused, separate pass in the main loop — the token savings still come from the compact structured output each pass returns.

| Role | Job | Access | Model |
|------|-----|--------|-------|
| **Fetcher** | Discover the target PR, pull open review threads + comments + check runs, tag each item as bot or human, return a normalized list | read-only | cheapest / fastest available |
| **Thinker** | Classify each item, write the summary, implement fixes, draft replies | read + write | configured, else session model; raised by `--high` / `--xhigh` |
| **Poller** | After a push, wait for re-requested bots to finish an async re-review, return only each bot's completion state (and failure head) | read-only | cheapest / fastest available |

The Poller is active **only for bots/automated agents** (review bots and scanners that re-review and post further comments). It waits for the completion signal, reports state, and never reads or fixes code — the next iteration's fixes go to the Thinker.

## The Loop

### 0. Resolve target and parse flags

- Parse `$ARGUMENTS` for the four flags. `--xhigh` overrides `--high`.
- Find the PR for the current branch via `~~source control`. If none, or several, ask which PR.
- **Thinker floor check.** Resolve the thinker model (effort flag → configured model → session model). If it lands on a fast/small tier (Haiku, `gpt-5-mini`, or the tool's small default) with no effort flag raising it, the thinker would be doing code judgment on a model built for data shuttling. Warn and confirm before proceeding, offering to: (a) run anyway as a fast, lower-confidence pass; (b) re-run with `--high` / `--xhigh`; or (c) raise the session or configured model. If no user is available to answer (unattended loop), proceed but mark the run low-confidence: auto-apply only unambiguous must-fix, and list should-fix / optional for review instead of changing them. The fetcher and poller on a small tier need no warning; only the thinker does.
- Confirm the effort and mode you resolved in one line, e.g. `PR #142 | effort: high | thinker: Opus 5 | scope: bots only | resolve: on`.

### 1. Fetch (Fetcher)

Pull, for the target PR:
- Open (unresolved) review threads with their file, line, diff hunk, full comment chain, and author.
- Top-level review bodies and issue comments that carry feedback.
- The author login of each item, so it can be tagged bot vs human (see **Bot detection**).
- The latest check runs / workflow runs and their authors.

Drop resolved threads and threads whose last reply is already yours. If `--bot-only`, keep only bot-authored items. Return a normalized list: `{id, thread_id (or none), author, is_bot, file, line, quote, body}`. Nothing is edited in this step.

### 2. Classify (Thinker)

Put every item in exactly one bucket. Rubric:

- 🔴 **Must fix** — correctness bug, security issue, data loss, broken build/test, contract violation, or a required-change review. Ship-blocking.
- 🟡 **Should fix** — real improvement the reviewer is right about: missing edge case, poor error handling, naming that hides intent, a test worth adding. Not blocking, but you would take it.
- 🔵 **Optional** — nits, style, preference, speculative refactors, "consider" comments. Take only if trivially safe.
- ⚪ **False positive** — the reviewer is wrong, the code is already correct, or the comment is stale against the current diff. No code change.

Judge against the **current** code, not the diff the reviewer saw — a comment may already be resolved by a later commit. When you cannot tell whether an ask is small, treat it as larger and float it rather than guessing.

### 3. Show the summary (before any code change)

Always print this before editing anything, grouped and colored:

```
Review summary for PR #142  (7 items)

🔴 Must fix (2)
  1. src/auth/token.rb:44  @coderabbitai  Token TTL compared in ms, not s
  2. lib/api/client.rb:88  @alice          Missing nil guard on response body

🟡 Should fix (2)
  3. src/auth/token.rb:52  @copilot        Extract magic number to constant
  4. spec/api_spec.rb:—    @alice          Add a timeout regression test

🔵 Optional (2)
  5. lib/api/client.rb:12  @copilot        Prefer keyword args
  6. README.md:30          @sonarcloud     Heading capitalization

⚪ False positive (1)
  7. src/auth/token.rb:44  @ox-security    "Hardcoded secret" — it is an ENV name, not a value
```

Color legend (emoji circles are the portable channel across terminals; a tool that renders ANSI may color the text too): 🔴 must fix, 🟡 should fix, 🔵 optional, ⚪ false positive.

Then proceed: apply all **must-fix** and **should-fix**. Apply **optional** only when trivially safe or when the user asked for them; otherwise list and skip. Never change code for a **false positive**. If a person is at the keyboard and the buckets are contentious, pause for a go-ahead; in an unattended loop, proceed on this policy.

### 4. Fix (Thinker)

Implement the fixes, smallest change that satisfies each comment. Do not widen scope beyond what the comments ask. Group related fixes so one commit maps to a coherent set. Before moving on, run the repo's fast checks (lint, typecheck, changed-package tests) and re-read your own diff adversarially.

### 5. Reply and (optionally) resolve

For every item you acted on or dismissed:

- **Reply in the thread it came from** — never as a standalone comment. Use the review-comment reply path so the reply nests under the original.
- **No thread available** (a plain PR/issue comment or a review body with no inline thread) → post one comment that **@-mentions the commenter** so it still routes to them.
- One reply per item. Keep it short, technical, no em-dash: state the what, not the why. `Fixed: compare TTL in seconds.` / `Added timeout regression test in spec/api_spec.rb.` / `Not a secret: TTL_ENV is the variable name, left as is.`
- With `--resolve`: resolve a thread once its fix is pushed. Resolve a false-positive thread only after replying with the reason. Leave a must-fix you could not resolve **open**, and say why in the reply. Without `--resolve`, reply only and leave every thread open.

### 6. Commit and push

Commit the batch with a short, technical message (what, not why, no em-dash), then push the branch. One validated push beats three speculative ones — only push after step 4's checks pass.

### 7. Re-request review

- Re-request every bot reviewer that supports it so it re-scans the new head. Copilot must be re-requested explicitly after each push (it does not re-review on its own). Check/scanner bots (CodeRabbit, ox-security, Sonar, Snyk, Semgrep) usually re-run on push; trigger the ones that do not.
- Record, per bot, the head SHA and the timestamp you re-requested at. This is the baseline step 8 uses to tell a fresh pass from a stale one.
- Re-request a human reviewer only when their thread was `changes-requested` and you addressed it.

### 8. Wait for the bot to finish, then read its new pass (Poller)

Bot re-review is **asynchronous and slow**. Copilot and scanners take from tens of seconds to many minutes depending on diff size and code complexity, and comments appear only when the pass completes. Do not read comments right after step 7 and call the bot clean — an empty result almost always means "not started yet," not "no suggestions."

The Poller watches for each re-requested bot's **completion signal**, not for comments:

- **Review-type bots (Copilot):** done when a review by that bot appears whose submitted-at is after your step-7 timestamp **and** the bot is no longer in the PR's requested/pending-reviewer list. Until both hold, it is still working.
- **Check-type bots (CodeRabbit, ox-security, Sonar, Snyk, Semgrep):** done when the bot's check run / action for the current head SHA reaches a completed conclusion (`success` / `failure` / `neutral`). A queued or in-progress run is still working.

Poll with backoff so the cheap model is not spinning: start ~20-30s, roughly double up to a ~2-3 min ceiling, with an overall per-bot timeout (default ~15 min). On Claude Code, prefer the PR activity subscription and **end the turn** — the completed-review or check event wakes the session and re-enters step 1; do not sleep-poll when a subscription is available.

The Poller returns only, per bot: `state` ∈ { working, done-clean, done-with-comments, timed-out } and, for check-type failures, the failure head.

- **done-with-comments** → feed the new comments to step 1 and loop.
- **done-clean** → that bot is satisfied; stop re-requesting it.
- **timed-out** → report it and move on. Never treat a timeout as clean.

A red **required** check your change caused is in scope to fix; a failure unrelated to the diff is reported, not chased here (that is `/babysit` territory).

### 9. Repeat or finish

Re-enter step 1 whenever a bot came back **done-with-comments** or a human posted new feedback. Keep the fix → reply → push → re-request → wait cycle going per bot.

A bot is **finished** only when it completed a fresh pass (step 8 confirmed the completion signal) that produced zero new suggestions — never because comments had simply not appeared yet. Stop when, for every in-scope reviewer, the last completed pass produced nothing new, `--bot-only` scope is clean, and no thread is left waiting on you.

**Loop guards** — do not spin forever:

- If a bot re-posts a suggestion you already addressed, reply once pointing to the resolution and stop re-requesting it. Do not re-fix.
- Cap re-review rounds per bot (default 5). At the cap, summarize what the bot still wants and hand back to the user.
- Make progress or stop: if a round changes no code and resolves no thread, do not re-request again.

Then report a final tally: items fixed, replied, resolved, bots that went quiet, and anything left open or timed-out with the reason.

## Bot detection

Treat an author as a bot when the login ends in `[bot]`, the account type is `Bot`, or it matches a known reviewer/scanner: `copilot`, `coderabbitai`, `dependabot`, `ox-security`, `sonarcloud`/`sonarqubecloud`, `github-actions`, `codecov`, `snyk-bot`, `renovate`, `deepsource`, `semgrep`. `--bot-only` keeps exactly these; the default addresses everyone.

## Comment and resolution rules

- In-thread reply is the default and strongly preferred; standalone comment (with an @-mention) is the fallback only when no thread exists.
- One reply per item, short and technical, what-not-why, no em-dash.
- `--resolve` resolves only threads you actually addressed (fixed, or false-positive with a stated reason). It never resolves an open must-fix you could not complete.
- Never resolve a human reviewer's thread you did not address.

## Operating Rules

- Show the grouped summary **before** the first code change, every iteration.
- One bucket per item. Judge against current code, not the stale diff.
- Never edit code for a false positive; reply instead.
- Never skip, disable, or quarantine a test to make a check pass. Never push an empty commit to kick CI.
- Do not widen a PR beyond what the comments ask; float larger refactors as a reply, do not silently perform them.
- The Poller returns results only. All fixes go through the Thinker.
- Never silently run the Thinker on the fetch/poll tier. If it resolves to a fast/small model with no effort flag, warn and confirm, or degrade autonomy when unattended (step 0).
- Never call a re-requested bot clean until its completion signal fired for the current head. An empty read before then is "still working," not "no suggestions."
- Never re-fix a suggestion the bot re-posts after you addressed it; reply once and stop re-requesting that bot.
- Stop immediately when the user says stop.

## If Connectors Available

If **~~source control** is connected: read review threads, comment authors, and check runs directly; reply in-thread, resolve threads, re-request reviewers, and push through it.

If **~~CI/CD** is connected: read bot/scanner run status and logs to decide when a loop iteration is clear.

## Tips

1. **Pick effort to match the PR.** Default for routine feedback, `--high` for tricky correctness threads, `--xhigh` for security or gnarly logic.
2. **`--bot-only` for a fast bot sweep** — clear Copilot/CodeRabbit/scanner noise before a human looks.
3. **Add `--resolve` once you trust the loop** — it closes threads as it fixes them so the reviewer sees only what is left.
