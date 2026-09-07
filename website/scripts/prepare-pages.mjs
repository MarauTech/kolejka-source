import { readFile, writeFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
const output = path.resolve('dist/client');
const prefix = '/kolejka';
// This download page needs no client-side state. Publish its prerendered HTML,
// without a router, so direct visits on GitHub's repository subpath work too.
async function prepare(directory) {
  for (const entry of await readdir(directory, {withFileTypes:true})) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) await prepare(file);
    else if (entry.name.endsWith('.html')) {
      let html = await readFile(file, 'utf8');
      html = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
        .replace(/<link\b[^>]*(?:rel="modulepreload"|as="script")[^>]*>/gi, '')
        .replace(/(href|src)="\/_next\//g, `$1="${prefix}/_next/`);
      await writeFile(file, html);
    }
  }
}
await prepare(output);
const index = await readFile(path.join(output,'index.html'),'utf8');
if (!index.includes('Kolej pod ręką.') || !index.includes('kolejka-1.0.0-beta.3.apk')) throw Error('Missing page content or APK link');
for (const match of index.matchAll(/(?:src|href)="(\/kolejka\/[^"?#]+)"/g)) {
  const relative = match[1].slice(prefix.length + 1);
  if (relative && !relative.endsWith('/')) await stat(path.join(output,relative));
}
if (/<script\b/i.test(index)) throw Error('Unexpected script in static download page');
console.log('GitHub Pages HTML and referenced assets verified.');
