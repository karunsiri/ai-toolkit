# Handoff Template Rules

Use @handoff-template.md as structure when creating handoff documents. The smart scaffold script
will pre-fill `{{TOKEN}}` fields automatically; complete the `[TODO: ...]` sections based on session
context.

**Security Reminder**: Before finalizing, run `python scripts/validate_handoff.py` to check for accidental secret exposure.

## Template Usage Notes

When filling the template:
1. Be specific and concrete - vague descriptions don't help the next agent
2. Include file paths with line numbers where relevant (e.g., `src/auth.ts:142`)
3. Prioritize the "Important Context" and "Immediate Next Steps" sections
4. Don't include sensitive data (API keys, passwords, tokens)
5. Focus on WHAT and WHY, not just WHAT - rationale is crucial for handoffs
6. `{{TOKEN}}` fields are auto-filled by `create_handoff.sh`; `[TODO: ...]` sections are for the AI agent to complete
