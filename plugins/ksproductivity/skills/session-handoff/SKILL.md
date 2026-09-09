---
name: session-handoff
description: Create or resume a project handoff document when the user asks to save or load session context, pause work, continue from a handoff, or check handoff staleness.
---

# Handoff

Creates comprehensive handoff documents that enable fresh AI agents to seamlessly continue work with zero ambiguity. Solves the long-running agent context exhaustion problem.

## Script Location

Before running any bundled script, set `SKILL_DIR` to the absolute directory that contains this `SKILL.md`. In Codex, use this skill's listed file path to determine that directory. All script commands below use `SKILL_DIR` so they work regardless of the project working directory.

## Mode Selection

Determine which mode applies:

**Creating a handoff?** User wants to save current state, pause work, or context is getting full.
- Follow: CREATE Workflow below

**Resuming from a handoff?** User wants to continue previous work, load context, or mentions an existing handoff.
- Follow: RESUME Workflow below

**Proactive suggestion?** After substantial work (7+ file edits, complex debugging, major decisions), suggest:
> "We've made significant progress. Consider creating a handoff document to preserve this context for future sessions. Say 'create handoff' when ready."

## CREATE Workflow

### Step 1: Generate Scaffold

Run the smart scaffold script to create a pre-filled handoff document:

```bash
bash "$SKILL_DIR/scripts/create_handoff.sh" [task-slug]
```

Example: `bash "$SKILL_DIR/scripts/create_handoff.sh" implementing-user-auth`

**For continuation handoffs** (linking to previous work):
```bash
bash "$SKILL_DIR/scripts/create_handoff.sh" "auth-part-2" --continues-from 2024-01-15-auth.md
```

The script will:
- Create `.agents/handoffs/` directory if needed
- Generate timestamped filename
- Pre-fill session metadata as YAML frontmatter at the top of the file:
  ```yaml
  ---
  title: Title of the task
  created: YYYY-MM-DD HH:MM:SS
  project: /path/to/project
  branch: main
  session_duration: [estimate how long you worked]
  ---
  ```
- Pre-fill body: recent commits, modified files
- Add handoff chain links if continuing from previous
- Output file path for editing

### Step 2: Complete the Handoff Document

Open the generated file and fill in all `[TODO: ...]` sections. Prioritize these sections:

1. **Current State Summary** - What's happening right now
2. **Important Context** - Critical info the next agent MUST know
3. **Immediate Next Steps** - Clear, actionable first steps
4. **Decisions Made** - Choices with rationale (not just outcomes)

Follow the rules in [references/handoff-template-rule.md](references/handoff-template-rule.md) for guidance.

### Step 3: Validate the Handoff

Run the validation script to check completeness and security:

```bash
bash "$SKILL_DIR/scripts/validate_handoff.sh" <handoff-file>
```

The validator checks:
- [ ] No `[TODO: ...]` placeholders remaining
- [ ] Required sections present and populated
- [ ] No potential secrets detected (API keys, passwords, tokens)
- [ ] Referenced files exist
- [ ] Quality score (0-100)

**Do not finalize a handoff with secrets detected or score below 70.**

### Step 4: Confirm Handoff

Report to user:
- Handoff file location
- Validation score and any warnings
- Summary of captured context
- First action item for next session

## RESUME Workflow

### Step 1: Find Available Handoffs

List handoffs in the current project:

```bash
bash "$SKILL_DIR/scripts/list_handoffs.sh"
```

This shows all handoffs with dates, titles, and completion status.

### Step 2: Check Staleness

Before loading, check how current the handoff is:

```bash
bash "$SKILL_DIR/scripts/check_staleness.sh" <handoff-file>
```

Staleness levels:
- **FRESH**: Safe to resume - minimal changes since handoff
- **SLIGHTLY_STALE**: Review changes, then resume
- **STALE**: Verify context carefully before resuming
- **VERY_STALE**: Consider creating a fresh handoff

The script checks:
- Time since handoff was created
- Git commits since handoff
- Files changed since handoff
- Branch divergence
- Missing referenced files

### Step 3: Load the Handoff

Read the relevant handoff document completely before taking any action.

If handoff is part of a chain (has "Continues from" link), also read the linked previous handoff for full context.

### Step 4: Verify Context

Follow the checklist in [references/resume-checklist.md](references/resume-checklist.md):

1. Verify project directory and git branch match
2. Check if blockers have been resolved
3. Validate assumptions still hold
4. Review modified files for conflicts
5. Check environment state

### Step 5: Begin Work

Start with "Immediate Next Steps" item #1 from the handoff document.

Reference these sections as you work:
- "Critical Files" for important locations
- "Key Patterns Discovered" for conventions to follow
- "Potential Gotchas" to avoid known issues

### Step 6: Update or Chain Handoffs

As you work:
- Mark completed items in "Pending Work"
- Add new discoveries to relevant sections
- For long sessions: create a new handoff with `--continues-from` to chain them

## Handoff Chaining

For long-running projects, chain handoffs together to maintain context lineage:

```
handoff-1.md (initial work)
    ↓
handoff-2.md --continues-from handoff-1.md
    ↓
handoff-3.md --continues-from handoff-2.md
```

Each handoff in the chain:
- Links to its predecessor
- Can mark older handoffs as superseded
- Provides context breadcrumbs for new agents

When resuming from a chain, read the most recent handoff first, then reference predecessors as needed.

## Storage Location

Handoffs are stored in: `.agents/handoffs/`

Naming convention: `YYYY-MM-DD-HHMMSS-[slug].md`

Example: `2024-01-15-143022-implementing-auth.md`

## Resources

### scripts/

> **Note:** `scripts/` paths are relative to this skill's root directory, not the project workspace. Set `SKILL_DIR` from this skill's location before running them.

| Script | Purpose |
|--------|---------|
| `create_handoff.sh [slug] [--continues-from <file>]` | Generate new handoff with smart scaffolding |
| `list_handoffs.sh [path]` | List available handoffs in a project |
| `validate_handoff.sh <file>` | Check completeness, quality, and security |
| `check_staleness.sh <file>` | Assess if handoff context is still current |

### references/

- [handoff-template.md](references/handoff-template.md) - Handoff document template (used by create_handoff.sh)
- [handoff-template-rule.md](references/handoff-template-rule.md) - Rules for completing handoff documents
- [resume-checklist.md](references/resume-checklist.md) - Verification checklist for resuming agents
