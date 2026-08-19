import { resolve } from "node:path";
import { root } from "./runtime.js";

const source = resolve(
  Bun.argv[2] ?? resolve(root, "..", "argiope-palettes", "dist", "argiope-themes.lua"),
);
const destination = resolve(root, "lua", "argiope", "generated", "themes.lua");
const file = Bun.file(source);
if (!await file.exists()) {
  throw new Error(`argiope: generated theme registry not found at ${source}`);
}
await Bun.write(destination, file);
console.log(`argiope: synced ${source} -> ${destination}`);
