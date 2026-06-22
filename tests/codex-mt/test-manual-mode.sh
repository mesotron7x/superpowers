#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

REPO_ROOT="$REPO_ROOT" node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const repoRoot = process.env.REPO_ROOT;
const manifestPath = path.join(repoRoot, '.codex-plugin', 'plugin.json');
const skillsDir = path.join(repoRoot, 'skills');

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

assert.equal(manifest.skills, './skills/', 'Codex manifest must still expose skills');
assert.equal(
  Object.prototype.hasOwnProperty.call(manifest, 'hooks'),
  false,
  'Codex MT manifest must not register session-start hooks'
);

const expectedSkillNames = [
  'brainstorming',
  'dispatching-parallel-agents',
  'executing-plans',
  'finishing-a-development-branch',
  'receiving-code-review',
  'requesting-code-review',
  'subagent-driven-development',
  'systematic-debugging',
  'test-driven-development',
  'using-git-worktrees',
  'using-superpowers',
  'verification-before-completion',
  'writing-plans',
  'writing-skills',
];

const skillFiles = fs.readdirSync(skillsDir, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => path.join(skillsDir, entry.name, 'SKILL.md'))
  .filter((file) => fs.existsSync(file))
  .sort();

const actualSkillNames = [];
const expectedDescription = 'Manual trigger only. Invoke this skill only when the user explicitly names this skill.';
const forbiddenDescriptionPatterns = [
  /\bUse when\b/i,
  /\bMUST use\b/i,
  /\bbefore any\b/i,
  /\bbefore writing\b/i,
  /\bbefore touching\b/i,
  /\bencountering any\b/i,
  /\bstarting any conversation\b/i,
];

for (const skillFile of skillFiles) {
  const relativePath = path.relative(repoRoot, skillFile);
  const content = fs.readFileSync(skillFile, 'utf8');
  const match = content.match(/^---\n([\s\S]*?)\n---\n/);
  assert.ok(match, `${relativePath} must have YAML frontmatter`);

  const frontmatter = Object.fromEntries(
    match[1].split('\n')
      .map((line) => {
        const separator = line.indexOf(':');
        if (separator === -1) return null;
        const key = line.slice(0, separator).trim();
        const value = line.slice(separator + 1).trim().replace(/^["']|["']$/g, '');
        return [key, value];
      })
      .filter(Boolean)
  );

  assert.ok(frontmatter.name, `${relativePath} must keep a name`);
  actualSkillNames.push(frontmatter.name);
  assert.equal(
    frontmatter.description,
    expectedDescription,
    `${relativePath} must use manual-only description metadata`
  );

  for (const pattern of forbiddenDescriptionPatterns) {
    assert.equal(
      pattern.test(frontmatter.description),
      false,
      `${relativePath} description must not contain contextual trigger phrase ${pattern}`
    );
  }
}

assert.deepEqual(actualSkillNames.sort(), expectedSkillNames, 'bundled skill names must remain unchanged');

console.log('Codex MT manual-mode manifest and skill metadata look good');
NODE
