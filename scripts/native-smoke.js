import { $ } from "bun";
import { existsSync, lstatSync, realpathSync } from "node:fs";
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
  const stateRoot = resolve(deps, "native-xdg");
  const environment = isolatedEnvironment("argiope-native", stateRoot);
  await ensureEnvironmentDirectories(environment);

  const packageRoot = resolve(
    environment.XDG_DATA_HOME,
    environment.NVIM_APPNAME,
    "site",
    "pack",
    "argiope",
    "start",
  );
  const packageLink = resolve(packageRoot, "argiope.nvim");
  await $`mkdir -p ${packageRoot}`;

  if (existsSync(packageLink)) {
    if (!lstatSync(packageLink).isSymbolicLink()) {
      throw new Error(
        `argiope: ${packageLink} exists and is not a symlink`,
      );
    }
    const actual = realpathSync(packageLink);
    if (actual !== root) {
      throw new Error(
        `argiope: ${packageLink} points to ${actual} instead of ${root}`,
      );
    }
  } else {
    await $`ln -s ${root} ${packageLink}`;
  }

  const assertion = [
    'vim.cmd("enew")',
    'vim.bo.filetype = "javascript"',
    'assert(vim.g.loaded_argiope == 1, "native package plugin was not loaded")',
    'assert(vim.b.argiope_attached == true, "argiope did not attach to a JavaScript buffer")',
    'assert(vim.b.argiope_highlight_attached == true, "argiope highlighting did not attach")',
    'assert(vim.bo.shiftwidth == 2, "argiope did not set shiftwidth=2")',
    'assert(vim.bo.expandtab, "argiope did not enable expandtab")',
  ].join("; ");

  const result =
    await $`${nvim} --headless -n -i NONE -u ${resolve(root, "tests", "native_init.lua")} --cmd ${`set runtimepath+=${resolve(deps, "runtime")}`} --cmd ${`set runtimepath+=${resolve(deps, "nvim-treesitter")}`} --cmd ${`set runtimepath+=${resolve(deps, "nvim-treesitter", "runtime")}`} -c ${`lua ${assertion}`} -c "qa!"`
      .cwd(root)
      .env(environment)
      .nothrow();
  if (result.exitCode !== 0) {
    process.exit(result.exitCode);
  }

  console.log("argiope: native package smoke test passed");
}

main().catch(reportFailure);
