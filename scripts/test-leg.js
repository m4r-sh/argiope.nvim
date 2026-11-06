import { resolve } from 'node:path';
const source = process.env.VIMOTE_SOURCE;
if (!source) throw new Error('Set VIMOTE_SOURCE to a Vimote checkout with bun run build:grammar completed.');
const runtime = resolve(source, 'editors/neovim');
if (!await Bun.file(resolve(runtime, 'parser/leg.so')).exists())
  throw new Error('Missing Leg parser. Run bun run build:grammar in Vimote first.');
const child = Bun.spawn(['bun', 'scripts/run-tests.js', 'tests/leg'], {
  cwd: resolve(import.meta.dir, '..'),
  env: {...process.env, ARGIOPE_LEG_RUNTIME: runtime},
  stdout: 'inherit', stderr: 'inherit',
});
process.exit(await child.exited);
