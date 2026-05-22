---
title: {{TASK_TITLE}}
created: {{TIMESTAMP}}
project: {{PROJECT_PATH}}
branch: {{GIT_BRANCH}}
session_duration: [estimate how long you worked]
---

# Handoff: {{TASK_TITLE}}

### Recent Commits (for context)
{{RECENT_COMMITS}}

{{CHAIN_SECTION}}

## Current State Summary

[TODO: Write one paragraph describing what was being worked on, current status, and where things left off]

## Codebase Understanding

### Architecture Overview

[TODO: Document key architectural insights discovered during this session]

### Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| [TODO: Add critical files] | | |

### Key Patterns Discovered

[TODO: Document important patterns, conventions, or idioms found in this codebase]

## Work Completed

### Tasks Finished

- [ ] [TODO: List completed tasks]

### Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
{{MOD_ROWS}}

### Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| [TODO: Document key decisions] | | |

## Pending Work

### Immediate Next Steps

1. [TODO: Most critical next action]
2. [TODO: Second priority]
3. [TODO: Third priority]

### Blockers/Open Questions

- [ ] [TODO: List any blockers or open questions]

### Deferred Items

- [TODO: Items deferred and why]

## Context for Resuming Agent

### Important Context

[TODO: This is the MOST IMPORTANT section - write critical information the next agent MUST know]

### Assumptions Made

- [TODO: List assumptions made during this session]

### Potential Gotchas

- [TODO: Document things that might trip up a new agent]

## Environment State

### Tools/Services Used

- [TODO: List relevant tools and their configuration]

### Active Processes

- [TODO: Note any running processes, servers, etc.]

### Environment Variables

- [TODO: List relevant env var NAMES only - NEVER include actual values/secrets]

## Related Resources

- [TODO: Add links to relevant docs and files]

---

**Security Reminder**: Before finalizing, run `python scripts/validate_handoff.py` to check for accidental secret exposure.
