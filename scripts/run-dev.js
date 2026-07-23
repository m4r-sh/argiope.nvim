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
  const files = Bun.argv.slice(2);
  if (files.length === 0) {
    files.push(resolve(root, "tests", "fixtures", "highlight", "embedded.js"));
  }
  const environment = isolatedEnvironment(
    "argiope-dev",
    resolve(deps, "dev-xdg"),
  );
  await ensureEnvironmentDirectories(environment);

  const result =
    await $`${nvim} -n -i NONE -u ${resolve(root, "tests", "dev_init.lua")} ${files}`
      .cwd(root)
      .env({
        ...environment,
        ARGIOPE_ROOT: root,
      })
      .nothrow();
  process.exit(result.exitCode);
}

main().catch(reportFailure);
