import { $ } from "bun";
import { resolve } from "node:path";

export const root = resolve(import.meta.dir, "..");
export const deps = resolve(root, ".deps");

export async function requireCommand(command, purpose) {
  const result = await $`command -v ${command}`.quiet().nothrow();
  if (result.exitCode !== 0) {
    throw new Error(`argiope: ${command} is required ${purpose}`);
  }
  return result.text().trim();
}

export async function resolveNvim() {
  const configured = process.env.NVIM_BIN?.trim();
  if (configured) {
    const result = await $`test -x ${configured}`.quiet().nothrow();
    if (result.exitCode !== 0) {
      throw new Error(`argiope: NVIM_BIN is not executable: ${configured}`);
    }
    return configured;
  }

  for (const candidate of ["nvim12", "nvim"]) {
    const result = await $`command -v ${candidate}`.quiet().nothrow();
    if (result.exitCode === 0) {
      return result.text().trim();
    }
  }

  throw new Error(
    "argiope: set NVIM_BIN to an executable Neovim 0.12+ binary",
  );
}

export function isolatedEnvironment(
  appName,
  stateRoot = resolve(deps, "xdg"),
) {
  return {
    ...process.env,
    XDG_CONFIG_HOME: resolve(stateRoot, "config"),
    XDG_DATA_HOME: resolve(stateRoot, "data"),
    XDG_STATE_HOME: resolve(stateRoot, "state"),
    XDG_CACHE_HOME: resolve(stateRoot, "cache"),
    NVIM_APPNAME: appName,
  };
}

export async function ensureEnvironmentDirectories(
  environment,
) {
  await $`mkdir -p ${environment.XDG_CONFIG_HOME} ${environment.XDG_DATA_HOME} ${environment.XDG_STATE_HOME} ${environment.XDG_CACHE_HOME}`;
}

export function reportFailure(error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
}
