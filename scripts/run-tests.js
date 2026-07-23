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
  const suite = Bun.argv[2] ?? "tests";
  const environment = isolatedEnvironment("argiope-test");
  await ensureEnvironmentDirectories(environment);

  const command =
    `PlenaryBustedDirectory ${suite} ` +
    "{ minimal_init = './tests/minimal_init.lua', sequential = true, keep_going = true }";

  const result =
    await $`${nvim} --headless --noplugin -n -i NONE -u ${resolve(root, "tests", "minimal_init.lua")} -c ${command}`
      .cwd(root)
      .env({
        ...environment,
        ARGIOPE_DEPS: deps,
      })
      .nothrow();
  process.exit(result.exitCode);
}

main().catch(reportFailure);
