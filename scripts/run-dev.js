import { $ } from "bun";
import { resolve } from "node:path";
import {
  deps,
  ensureEnvironmentDirectories,
  isolatedEnvironment,
  reportFailure,
  resolveNvim,
  root,
} from "./runtime.js";

async function main() {
  const nvim = await resolveNvim();
  const environment = isolatedEnvironment(
    "argiope-dev",
    resolve(deps, "dev-xdg"),
  );
  await ensureEnvironmentDirectories(environment);

  const result =
    await $`${nvim} -n -i NONE -u ${resolve(root, "dev", "init.lua")} ${Bun.argv.slice(2)}`
      .cwd(root)
      .env({
        ...environment,
        ARGIOPE_ROOT: root,
      })
      .nothrow();
  process.exit(result.exitCode);
}

main().catch(reportFailure);
