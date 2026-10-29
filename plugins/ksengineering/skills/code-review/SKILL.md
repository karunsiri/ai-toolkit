---
name: code-review
description: Review a code change for correctness, security, performance, design, and tests, then give short, kind, labeled feedback (blocker / suggestion / nit) as inline comments on the PR. Trigger with "/code-review", "review this PR", "review my diff", or when checking a change for N+1 queries, injection risks, missing edge cases, or weak error handling. Do NOT trigger to work through review comments already on your own PR (that is /address-reviews).
argument-hint: "[PR number | PR URL | branch | path]"
---

# /code-review

Review a change like a good senior teammate: understand the problem first, check what matters most, then say it short and kind. Keep three things in balance: code quality, architectural fit, and how the feedback lands with the author.

Approve when the change makes the code healthier overall, even if it is not perfect. Block only on real problems, never on taste.

## Usage

```
/code-review [PR number | PR URL | branch | path]
```

No argument: review the PR for the current branch if one exists, else the local diff (staged, unstaged, and commits ahead of the base branch).

## Model Tiers

Tiers come from the shared [model tiers](../../references/model-tiers.md).

| Step | Tier | Who |
|------|------|-----|
| Fetch PR, linked ticket, CI status, diff, open threads | light | `ks-scout`, or a low-effort pass on Codex |
| Find callers and usages outside the diff | light | `ks-scout` |
| Review and draft comments (steps 2-3) | session model by default; deep if the user picks it | main session, or `ks-thinker` |
| Post comments | inline | main session |

**Ask once, before step 1.** Use the tool's question prompt (`AskUserQuestion` in Claude Code, `AskQuestion` in Cursor; in Codex ask in plain text and stop). One question, two options:

1. **Session model** (default). Review on the current model.
2. **Deep tier.** Stronger model, high effort.
   - Claude Code: if the session already runs a deep-tier model, review in the session. Else hand steps 2-3 to `ks-thinker` with a brief: the step 1 context, the diff, caller findings, and the focus list and label rules below. It returns findings; the session shows and posts them.
   - Cursor and Codex: ask the user to switch to a strong model (model selector, or `/model` with `model_reasoning_effort=high`) and say "continue". Wait for it.

Never switch models on your own. If the session model is a fast/small one (Haiku, a `-mini` model, effort `low`), say so in the question. Ask once per run. No one to answer (unattended run): use the session model.

## Steps

### 0. Resolve the target

- Find the PR from the argument or the current branch via `~~source control` (`gh pr view`, `glab mr view`, or the Bitbucket API). Several matches: ask which one. None: review the local diff.
- Confirm in one line, e.g. `PR #142 (GitHub) | tier: session | 312 lines in 9 files`.

### 1. Pre-review and context

- **Understand the problem.** Read the PR title, description, and linked issue or ticket. Write one line on what it solves and why. If you cannot tell, your first comment asks the author.
- **Check CI.** Read every required check. Red: report the failing check and its first error line, then ask whether to review anyway or wait. Still running: say so and ask the same. Local diff: no CI, so note which checks you did not run.
- **Check size.** Over ~400 changed lines (not counting lockfiles, generated code, snapshots): say so, review file by file, and suggest a split if it mixes concerns (see [Writing Reviewer-Friendly Pull Requests](https://dev.to/365talents/how-to-write-reviewer-friendly-pull-requests-16aj)).
- **Read open threads** so you do not repeat a point someone already made.
- **Find callers.** For each changed public function, signature, API response, schema, or config key, have `ks-scout` list usages outside the diff (`file:line` only).

### 2. Review

Read every changed line and the code around it, not only the diff hunk. Style that a linter or formatter can catch is not your job.

**Functionality and logic**
- Does it do what the PR and ticket say? Meets the acceptance criteria, if any. Trace one real input end to end.
- Edge cases: nil/null, empty, zero and negative, boundaries and off-by-one, time zones, very large input.
- Errors: swallowed exceptions, too-broad `rescue`/`catch`, network calls with no timeout, retries that are not idempotent, partial failure that leaves bad state.
- Concurrency: races, check-then-act, shared mutable state, missing transaction or lock.
- Contracts: a changed signature, response, schema, or config key that breaks a caller from step 1.

**Architecture and design**
- Fits the existing module boundaries, design patterns, and data flow. Dependencies point the same way as the rest of the code.
- Reuses existing helpers and patterns instead of new copies.
- No abstraction, option, or layer nobody needs yet. Logic lives in the right layer (not business rules in controllers or views).
- Migrations: reversible, safe on a big table, and backward compatible during a rolling deploy.

**Readability and naming**
- Names say what a thing is or does, and make sense in a diff with no IDE.
- Functions do one thing. Deep nesting and long functions are hard to follow.
- Comments explain why, not what. No dead or commented-out code.

**Testing**
- New or changed logic has tests for the happy path, the failure path, and edge cases.
- Tests would fail if the code broke. Watch for tests that only check mocks or assert nothing.
- A bug fix comes with a regression test. No flaky patterns (sleeps, real clock, order dependence).

**Security and performance**
- Injection: SQL built from strings or raw params in `order`/`where`, shell calls with user input, XSS (`html_safe`, `raw`, `dangerouslySetInnerHTML`), path traversal, unsafe deserialization (`YAML.load`, `Marshal.load`, `pickle`).
- Input validated at trust boundaries: HTTP params, webhooks, queue messages, uploads. No mass assignment.
- Every new endpoint or query checks who can access it. Scope lookups to the current user or tenant (no IDOR).
- No secrets in code, logs, error messages, or URLs. No SSRF or open redirect from user-given URLs.
- Infra and config: no public buckets, open security groups, `*` IAM, or privileged containers without a reason.
- N+1 queries: a query inside a loop or per-row association access. Rails: `includes`/`preload`; elsewhere batch or join.
- Unbounded work: queries with no limit or pagination, whole tables loaded into memory, no index for a new filter or sort.
- Hot paths: network calls inside a loop or the request path, repeated work that could run once.

### 3. Write the feedback

Give every finding exactly one label:

| Label | When | Blocks merge |
|-------|------|--------------|
| 🔴 **Blocker** | Bug, security flaw, data loss, breaks a caller or the build | yes |
| 🟡 **Suggestion** | Real improvement: a missing test, clearer design, an unlikely edge case | no |
| 🔵 **Nit** | Minor style, naming, or formatting preference | no |
| 👍 **Nice** | Something done well: a clever solution, clean code, a good test | no |

Not sure it is a blocker? It is not. Ask a question instead.

- One finding per comment: what is wrong, why it matters, and the fix. Add a snippet or link when it helps.
- Talk about the code, never the person. "This query runs once per row", not "You wrote an N+1".
- Unsure? Ask: "What happens when `user` is nil here?"
- Facts and data beat opinion. The style guide beats personal taste. No rule? Go with the author's choice.
- Call out at least one real, specific thing done well. No fake praise.
- Three nits max. Skip anything a linter catches.
- Do not comment on unchanged code unless the change breaks it. Bigger refactor ideas go in one Suggestion, marked as a follow-up.

**Voice.** Every comment and summary: talk like a friend. Shortest, fewest sentences. Simple English, like you are talking to a high school student. Keep technical terms and details correct. No em-dash. Do not show off your reasoning; say the problem and the fix. Never use "loose ends", "gaps", or "moot".

````markdown
**Blocker:** `params[:sort]` goes straight into `order()`, so this is SQL injection. Allowlist it:
```ruby
SORTS = %w[name created_at].freeze
scope.order(SORTS.include?(params[:sort]) ? params[:sort] : "created_at")
```

**Suggestion:** `rows.each` calls `row.user` every time, so it runs one query per row (N+1). `includes(:user)` makes it one query.

**Nit:** `tmp` doesn't say much. Maybe `header_row`?

**Nice:** Streaming the CSV keeps memory flat on big exports. Good call on the empty-file test too. 👍
````

### 4. Show, then deliver

Always print the summary before posting anything:

```
Review: PR #142  Add CSV export  (CI green, 312 lines, 9 files)
Solves: users need report exports; adds a streaming CSV endpoint.

🔴 Blockers (1)
  1. app/controllers/exports_controller.rb:18   SQL injection via params[:sort]

🟡 Suggestions (2)
  2. app/models/report.rb:40-52                 N+1 on row.user, add includes(:user)
  3. spec/requests/exports_spec.rb              No test for an empty report

🔵 Nits (1)
  4. app/services/csv_builder.rb:7              `tmp` hides intent

👍 Nice (1)
  5. app/services/csv_builder.rb:20-34          Streaming keeps memory flat

Verdict: request changes (1 blocker)
```

Verdict: any blocker means request changes. No blocker means approve; suggestions and nits stay non-blocking. CI red means comment only.

**Local diff:** the summary is the review. Stop here.

**On a PR:** posting is public, so ask once how to post: the verdict (recommended), comment only, or do not post. On your own PR, GitHub allows comment only.

**Inline comments, always.** A finding tied to a line or range goes on that line or range. Never post a standalone comment that points at a line.

- Batch every comment into one review, so the author gets one notification. The review body holds one kind line plus the counts. Do not repeat the inline text there.
- Anchor on lines inside the diff: added or context lines on the new side, removed lines on the old side. Platforms reject lines outside the diff.
- A finding on code outside the diff (a caller that breaks): anchor it on the changed line that causes it. No such line: put it in the review body with `path:line`.
- Small fix: use a `suggestion` code block (GitHub and GitLab) so the author applies it in one click.
- If the platform cannot span a range, anchor the first line and name the range in the text (`lines 40-52`).

| Platform | How |
|----------|-----|
| GitHub | One review: `POST /repos/{owner}/{repo}/pulls/{n}/reviews` with `commit_id` (head SHA), `event` (`COMMENT`, `REQUEST_CHANGES`, `APPROVE`), `body`, and `comments[]` of `{path, line, side, body}`. Add `start_line` and `start_side` for a range. With `gh`, write the JSON to a temp file and run `gh api repos/{owner}/{repo}/pulls/{n}/reviews --input <file>`. With the GitHub MCP, open a pending review, add each line comment, and submit once. |
| GitLab | One discussion per finding: `POST /projects/:id/merge_requests/:iid/discussions` with a `position` (`position_type: text`, `base_sha`, `start_sha`, `head_sha` from the MR's `diff_refs`, plus `new_path` and `new_line`; `old_path` and `old_line` for removed lines; `line_range` for a range). `glab api` works. Approve with `glab mr approve` only if the user picked it; blockers stay as open threads. |
| Bitbucket Cloud | `POST /2.0/repositories/{workspace}/{repo}/pullrequests/{id}/comments` with `content.raw` and `inline: {path, to}` (`to` is the new-file line, `from` the old-file line). Use the PR's `/approve` or `/request-changes` endpoint only if the user picked it. |

After posting, give the review link and the counts.

## Operating Rules

- Understand the problem and check CI before the deep read.
- Ask about the deep tier once per run, before step 1. Default to the session model.
- Every finding gets one label. Unsure means not a blocker.
- Comment on the code, never the person. Explain why. Real, specific praise only.
- Do not block on taste. Approve when the change makes the code healthier overall.
- Show the summary before posting. Never approve or request changes without the user's pick.
- Every line-level finding goes inline on its line or range, batched into one review.
- Never push code to the PR. This skill reviews; fixing is the author's job (or `/address-reviews` on their side).

## If Connectors Available

If **~~source control** is connected: fetch the PR, diff, open threads, and check runs, and post the review inline through it.

If **~~CI/CD** is connected: read the failing job's log for step 1.

If **~~project tracker** is connected: read the linked ticket's acceptance criteria and check the change meets them.
