#!/usr/bin/env node
// Wraps a body fragment written by the render-html skill in the shared shell
// (styles, light/dark theme), and stamps which markdown sources it came from.
//
//   node build.mjs <body.html> <out.html> "<title>" <source.md>...
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const [bodyPath, outPath, title, ...sources] = process.argv.slice(2);
if (!bodyPath || !outPath || !title) {
  console.error(
    'usage: build.mjs <body.html> <out.html> "<title>" <source.md>...',
  );
  process.exit(2);
}

const here = dirname(fileURLToPath(import.meta.url));
const shell = readFileSync(join(here, 'shell.html'), 'utf8');
const body = readFileSync(bodyPath, 'utf8');

const escapeHtml = (text) =>
  text.replace(
    /[&<>"]/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c],
  );

const stamps = sources.map((src) => {
  const hash = createHash('sha256')
    .update(readFileSync(src))
    .digest('hex')
    .slice(0, 8);
  return `<code>${escapeHtml(relative(process.cwd(), src))}</code> (${hash})`;
});
const generated = new Date().toISOString().slice(0, 16).replace('T', ' ');
const footer =
  `Generated ${generated} UTC from ${stamps.join(', ') || 'markdown'}. ` +
  'The markdown is the source of truth: if they differ, trust the markdown and regenerate this page.';

let lang = 'en';
try {
  const cfg = JSON.parse(readFileSync(join(process.cwd(), '.agents/project.json'), 'utf8'));
  if (typeof cfg.docsLanguage === 'string' && cfg.docsLanguage) lang = cfg.docsLanguage;
} catch {
  // no project config: keep English
}

const html = shell
  .replace('{{LANG}}', () => escapeHtml(lang))
  .replace('{{TITLE}}', () => escapeHtml(title))
  .replace('{{BODY}}', () => body)
  .replace('{{FOOTER}}', () => footer);

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, html);
console.log(outPath);
