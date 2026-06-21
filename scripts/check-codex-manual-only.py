#!/usr/bin/env python3
"""Validate that the Codex plugin remains manual-only.

This check intentionally focuses on Codex-specific activation paths:
- the Codex plugin manifest must not point at the startup bootstrap hooks;
- the manual-only hook file must define no hooks;
- every bundled skill must disable implicit invocation for Codex;
- using-superpowers must not advertise itself as a startup skill.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_PLUGIN_NAME = "superpowers-manual"
EXPECTED_HOOK_FILE = "./hooks/hooks-codex-manual-only.json"
EXPECTED_POLICY = "allow_implicit_invocation: false"


def fail(errors: list[str]) -> None:
    print("Codex manual-only check failed:", file=sys.stderr)
    for error in errors:
        print(f"  - {error}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    errors: list[str] = []

    manifest_path = ROOT / ".codex-plugin" / "plugin.json"
    if not manifest_path.exists():
        errors.append(f"{manifest_path}: missing")
    else:
        manifest = json.loads(manifest_path.read_text())
        if manifest.get("name") != EXPECTED_PLUGIN_NAME:
            errors.append(
                f"{manifest_path}: name must be {EXPECTED_PLUGIN_NAME!r}"
            )
        if manifest.get("hooks") != EXPECTED_HOOK_FILE:
            errors.append(
                f"{manifest_path}: hooks must be {EXPECTED_HOOK_FILE!r}"
            )

    hook_path = ROOT / "hooks" / "hooks-codex-manual-only.json"
    if not hook_path.exists():
        errors.append(f"{hook_path}: missing")
    else:
        hooks_config = json.loads(hook_path.read_text())
        if hooks_config.get("hooks") not in ({}, None):
            errors.append(f"{hook_path}: must not define active hooks")

    for skill_md in sorted((ROOT / "skills").glob("*/SKILL.md")):
        cfg = skill_md.parent / "agents" / "openai.yaml"
        if not cfg.exists():
            errors.append(f"{cfg}: missing")
            continue

        if EXPECTED_POLICY not in cfg.read_text():
            errors.append(f"{cfg}: must contain {EXPECTED_POLICY!r}")

    using_superpowers = ROOT / "skills" / "using-superpowers" / "SKILL.md"
    if using_superpowers.exists():
        first_chunk = using_superpowers.read_text()[:1000]
        if "starting any conversation" in first_chunk:
            errors.append(
                f"{using_superpowers}: frontmatter still advertises startup use"
            )

    if errors:
        fail(errors)

    print("Codex manual-only check passed.")


if __name__ == "__main__":
    main()
