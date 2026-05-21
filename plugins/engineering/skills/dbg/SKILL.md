---
name: dbg
description: Structured debugging session — reproduce, isolate, diagnose, and fix. Trigger with an error message or stack trace, "this works in staging but not prod", "something broke after the deploy", or when behavior diverges from expected and the cause isn't obvious.
argument-hint: "<error message or problem description>"
---

# /dbg

Run a structured debugging session. Four steps, strict order. No fix before reproduction. No hypothesis without evidence.

## Usage

```
/dbg $ARGUMENTS
```

## What I Need From You

Tell me about the problem. Any of these help:
- Error message or stack trace
- Steps to reproduce
- What changed recently
- Logs or screenshots
- Expected vs. actual behavior

## Steps

### 1. Reproduce

Understand the problem before touching code.

- **Expected vs. actual behavior** — clarify what should happen and what happens instead. Get the exact error message or symptom.
- **Reproduction steps** — capture the steps that trigger the issue. Aim for a runnable artifact when possible: failing test, curl command, CLI invocation, log snippet.
- **Scope** — when did it start? Who is affected? What environment? (prod only? certain region? specific inputs? one pod or all?)

If the user isn't sure how to reproduce:
- Suggest specific places to check: logs, recent deploys, config diffs, dependency updates, error tracking dashboards, infra metrics.
- Offer a few targeted directions: "Does this happen on a fresh session?", "Does it reproduce on a different node/pod?", "What changed between when it last worked and now?", "Can you trigger it with a smaller input?"

Pin what matters: environment, timing, input shape, infrastructure state.

### 2. Isolate

Narrow down the component, service, or code path. Try in this order — escalate only when the prior tactic fails:

1. **Attach a debugger.** Use the native debugger first. One breakpoint beats ten logs.
   - Ruby: offer `binding.pry` or `binding.irb`
   - Python: `breakpoint()` or `pdb`
   - JS/TS: `debugger` statement + DevTools / `--inspect`
   - Go/Rust/C: `dlv` / `gdb` / `lldb`
2. **Source trace + knob enumeration.** Trace the code path end-to-end. List every knob: config flags, env vars, feature toggles, branch conditions, input shape, timing, concurrency. Flip one at a time.
3. **In-code instrumentation.** Add targeted log/print statements at the suspected fail site. Tag each probe with a unique prefix (e.g. `[DBG-a4f2]`) so cleanup is a single grep.

Also check: recent deploys, config changes, dependency updates, and anything that correlates with when the issue started.

### 3. Diagnose

Generate **2–4 ranked hypotheses**. Not one. Single-hypothesis thinking anchors on the first plausible idea.

For each hypothesis:
- Does it explain the symptom end-to-end?
- What is the simplest proof? What is the cleanest disproof?
- **Run the disproof first.** If the hypothesis survives, it's real. If not, you saved a chase.

Cross-reference against the **debug ledger** (see below). Every new hypothesis must hold for **all** prior observations, not just the latest run. If any past run contradicts it — refine or discard.

### 4. Fix

- Propose a fix with clear explanation of why it works.
- Walk through side effects and edge cases.
- Suggest a test that would have caught this and will prevent regression.

## Debug Ledger

Maintain a running record of every experiment in `.claude/debug-sessions/{session_name}.md`.

Session name: slug from the issue, e.g. `auth-timeout-2026-05-21`.

Format:

```markdown
# Debug: {issue summary}

## Context
- **Expected**: [what should happen]
- **Actual**: [what happens instead]
- **Reproduction state**: reliable | flaky | none

## Experiment Log

| # | What changed | Result | Ruled in / out |
|---|-------------|--------|----------------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

## Hypotheses
1. [hypothesis] — status: testing | disproved | confirmed
2. ...

## Root Cause
[filled when confirmed. Explanation of why the bug occurs]

## Fix
[code changes or config fix applied]

## Prevention
- [test added]
- [guard added]
```

Update the ledger after every experiment. When stuck, read the full ledger — the answer is often in the pattern across runs.

## Operating Rules

- Do not propose a fix before reproduction steps are understood. If reliable repro isn't possible, document what is known and proceed with caution.
- Do not start testing hypotheses before isolation has narrowed the fail path.
- Do not commit to a hypothesis before attempting to disprove it.
- Do not declare a hypothesis correct until the ledger confirms it against every prior run.
- If you catch yourself proposing a fix without a reproduction, stop and return to step 1.

## If Connectors Available

If **~~monitoring** is connected:
- Pull logs, error rates, and metrics around the time of the issue
- Show recent deploys and config changes that may correlate

If **~~source control** is connected:
- Identify recent commits that touched affected code paths
- Check if the issue correlates with a specific change

If **~~project tracker** is connected:
- Search for related bug reports or known issues
- Create a ticket for the fix once identified

## Tips

1. **Share error messages exactly** — the exact text matters, don't paraphrase.
2. **Mention what changed** — recent deploys, dependency updates, config changes are top suspects.
3. **Include context** — "only in prod", "only large payloads", "started Thursday" narrows fast.
