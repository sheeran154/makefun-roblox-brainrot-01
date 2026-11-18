// Meme Menagerie — Brainrot Bazaar: the entrypoint the grader runs as
// `node /bot/main.ts` with NO network (Node 22, standard library only).
//
// It hands the game in: game.rbxl (the Rojo-built place), src/ (the Luau the
// place was built from), screenshots/ (Studio captures, when they exist) and
// PLAY.json (the published experience's link) are copied to /output, and
// /output/dossier.json is written with the kit's vendored library — the same
// summary the judge reads.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: the grader fails an entry whose output holds any
// other name, so src/ and screenshots/ are copied without any file or folder
// whose name starts with a dot (.gitkeep, .DS_Store, .git).
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// Deterministic: the same repository always produces the same /output bytes —
// no timestamps, no random values, files copied in a fixed order.

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Leave out every file and directory whose name starts with a dot. */
function notDotted(path: string): boolean {
  return !basename(path).startsWith('.');
}

function fail(message: string): never {
  throw new Error(`main.ts: ${message}`);
}

// The place file is the entry: refuse to hand in an empty output.
const placePath = join(here, 'game.rbxl');
if (!existsSync(placePath)) fail('game.rbxl is missing — build it first: rojo build default.project.json --output game.rbxl');
if (statSync(placePath).size === 0) fail('game.rbxl is empty');

const playPath = join(here, 'PLAY.json');
if (!existsSync(playPath)) fail('PLAY.json is missing — it names the published Roblox experience');

mkdirSync(out, { recursive: true });

// Copy in a fixed order so the output is identical on every run.
copyFileSync(placePath, join(out, 'game.rbxl'));
copyFileSync(playPath, join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// Sanity: never ship an empty src/ — the gate needs at least one script.
const srcFiles = readdirSync(join(out, 'src'), { recursive: true });
if (srcFiles.length === 0) fail('src/ copied nothing — the place would hold no scripts');

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the
// bytes; the others refuse an entry the scorer would refuse (more than 4
// screenshots or one over 256 KiB; a place of more than 500000 instances,
// whose scripts' sources come to over 8 MiB or whose scripts' paths come to
// over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);

console.log(`main.ts: handed in game.rbxl (${statSync(join(out, 'game.rbxl')).size} bytes), ${srcFiles.length} src entries, ${readdirSync(join(out, 'screenshots')).length} screenshots -> ${out}`);
