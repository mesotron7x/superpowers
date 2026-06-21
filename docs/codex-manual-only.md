# Codex Manual-Only Superpowers

This fork keeps the Superpowers workflows available for Codex, but disables automatic activation.

## Behavior

- Codex session startup, resume, and clear events do not inject `using-superpowers`.
- Bundled skills do not activate implicitly from their descriptions.
- Skills remain available through explicit Codex skill invocation, for example `$brainstorming`, `$systematic-debugging`, `$writing-plans`, or whatever name Codex displays in `/skills`.

## Implementation

Codex-specific manual-only behavior is enforced in three places:

1. `.codex-plugin/plugin.json` points to `./hooks/hooks-codex-manual-only.json`.
2. `hooks/hooks-codex-manual-only.json` defines an empty hooks map.
3. Every skill has `skills/<skill>/agents/openai.yaml` with:

```yaml
policy:
  allow_implicit_invocation: false
```

`skills/using-superpowers/SKILL.md` is also reworded so its description no longer advertises itself as a startup skill.

## Validation

Run:

```bash
python3 scripts/check-codex-manual-only.py
```

Expected output:

```text
Codex manual-only check passed.
```

## Usage

Use Superpowers explicitly:

```text
$brainstorming Help me design this feature.
$systematic-debugging Help me investigate this bug.
$writing-plans Turn this spec into an implementation plan.
```

Normal Codex conversations should not activate Superpowers unless one of these skills is explicitly invoked.
