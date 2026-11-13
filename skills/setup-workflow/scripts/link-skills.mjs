#!/usr/bin/env node
// Makes every skill in .agents/skills visible to agents that read their own
// folder (Claude Code reads .claude/skills). Fixes Windows checkouts, where git
// turns committed symlinks into small text files holding the target path.
//
//   node .agents/skills/setup-workflow/scripts/link-skills.mjs [dir ...]
//
// Default dir: .claude/skills. Each skill becomes a symlink; on Windows without
// symlink rights, a junction (no admin needed); if that fails, a copy.
// Copies don't follow `npx skills update`: run this again after an update.
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const root = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
const source = path.join(root, '.agents', 'skills');
if (!fs.existsSync(source)) {
  console.error('No .agents/skills here. Run `npx skills add <kit>` first.');
  process.exit(1);
}
const dirs = process.argv.slice(2).length ? process.argv.slice(2) : ['.claude/skills'];
const skills = fs.readdirSync(source).filter((n) => fs.existsSync(path.join(source, n, 'SKILL.md')));
const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };

for (const dir of dirs) {
  const target = path.join(root, dir);
  // A broken checkout of a whole-folder symlink: a file, or a link that doesn't resolve.
  const lst = fs.lstatSync(target, { throwIfNoEntry: false });
  if (lst && !isDir(target)) fs.rmSync(target, { force: true });
  if (isDir(target) && fs.realpathSync(target) === fs.realpathSync(source)) {
    console.log(`ok   ${dir} -> .agents/skills`);
    continue;
  }
  fs.mkdirSync(target, { recursive: true });
  const used = new Set();
  for (const name of skills) {
    const link = path.join(target, name);
    const from = path.join(source, name);
    if (isDir(link) && fs.existsSync(path.join(link, 'SKILL.md'))) continue;
    fs.rmSync(link, { recursive: true, force: true });
    try {
      fs.symlinkSync(path.relative(target, from), link, 'dir');
      used.add('symlink');
    } catch {
      try {
        fs.symlinkSync(from, link, 'junction');
        used.add('junction');
      } catch {
        fs.cpSync(from, link, { recursive: true });
        used.add('copy');
      }
    }
  }
  const count = fs.readdirSync(target).filter((n) => fs.existsSync(path.join(target, n, 'SKILL.md'))).length;
  console.log(`ok   ${dir}: ${count}/${skills.length} skills${used.size ? ` (${[...used].join(', ')})` : ''}`);
  if (used.has('copy')) console.log('     Copies: run this script again after `npx skills update`.');
}
// Committed symlinks that this machine can't check out (Windows) now look
// changed to git. Tell git to leave them alone here, so nobody commits the fix.
const tracked = execSync(`git ls-files -s -- ${dirs.map((d) => JSON.stringify(d)).join(' ')}`, { cwd: root, encoding: 'utf8' })
  .split('\n').filter((l) => l.startsWith('120000')).map((l) => l.split('\t')[1]);
let symlinksOff = process.platform === 'win32';
try { symlinksOff ||= execSync('git config core.symlinks', { cwd: root, encoding: 'utf8' }).trim() === 'false'; } catch {}
const broken = symlinksOff;
if (tracked.length && broken) {
  execSync(`git update-index --skip-worktree -- ${tracked.map((t) => JSON.stringify(t)).join(' ')}`, { cwd: root });
  console.log(`     git will ignore local changes to ${tracked.length} committed link(s).`);
}
