import { $ } from "bun";
import {
  chmod,
  copyFile,
  lstat,
  mkdir,
  mkdtemp,
  readlink,
  rm,
  symlink,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import {
  dirname,
  isAbsolute,
  relative,
  resolve,
} from "node:path";
import { pathToFileURL } from "node:url";
import {
  deps,
  ensureEnvironmentDirectories,
  isolatedEnvironment,
  reportFailure,
  resolveNvim,
  root,
} from "./runtime.js";

const gitEnvironment = {
  ...process.env,
  GIT_ALLOW_PROTOCOL: "file",
  GIT_CONFIG_GLOBAL: "/dev/null",
  GIT_CONFIG_NOSYSTEM: "1",
  GIT_TERMINAL_PROMPT: "0",
};

function parseNullSeparated(output) {
  return output.split("\0").filter(Boolean);
}

async function publishableFiles() {
  const [candidateResult, ignoredTrackedResult] = await Promise.all([
    $`git ls-files --cached --others --exclude-standard -z`
      .cwd(root)
      .quiet(),
    $`git ls-files --cached --ignored --exclude-standard -z`
      .cwd(root)
      .quiet(),
  ]);
  const ignoredTracked = new Set(
    parseNullSeparated(ignoredTrackedResult.text()),
  );

  return [
    ...new Set(parseNullSeparated(candidateResult.text())),
  ].filter((path) => !ignoredTracked.has(path));
}

function sourcePathFor(relativePath) {
  const sourcePath = resolve(root, relativePath);
  const pathFromRoot = relative(root, sourcePath);
  if (
    pathFromRoot === "" ||
    pathFromRoot === ".." ||
    pathFromRoot.startsWith(`..${process.platform === "win32" ? "\\" : "/"}`) ||
    isAbsolute(pathFromRoot)
  ) {
    throw new Error(
      `argiope: refusing to snapshot path outside the repository: ${relativePath}`,
    );
  }
  return sourcePath;
}

async function copyPublishableFile(relativePath, snapshotRoot) {
  const sourcePath = sourcePathFor(relativePath);
  const destinationPath = resolve(snapshotRoot, relativePath);
  let stat;
  try {
    stat = await lstat(sourcePath);
  } catch (error) {
    if (error?.code === "ENOENT") {
      return false;
    }
    throw error;
  }

  await mkdir(dirname(destinationPath), { recursive: true });
  if (stat.isSymbolicLink()) {
    await symlink(await readlink(sourcePath), destinationPath);
  } else if (stat.isFile()) {
    await copyFile(sourcePath, destinationPath);
    await chmod(destinationPath, stat.mode & 0o777);
  } else {
    throw new Error(
      `argiope: publishable path is not a file or symlink: ${relativePath}`,
    );
  }
  return true;
}

async function createSnapshot(snapshotRoot) {
  await mkdir(snapshotRoot, { recursive: true });

  let copied = 0;
  for (const relativePath of await publishableFiles()) {
    if (await copyPublishableFile(relativePath, snapshotRoot)) {
      copied += 1;
    }
  }
  if (copied === 0) {
    throw new Error("argiope: no publishable files found for native smoke test");
  }

  await $`git init --quiet --initial-branch=main ${snapshotRoot}`
    .cwd(root)
    .env(gitEnvironment);
  await $`git add --all`
    .cwd(snapshotRoot)
    .env(gitEnvironment);
  await $`git -c user.name=argiope-native-test -c user.email=argiope-native-test.invalid commit --quiet --no-gpg-sign -m "Native smoke snapshot"`
    .cwd(snapshotRoot)
    .env(gitEnvironment);
  await $`git tag v0.1.0`
    .cwd(snapshotRoot)
    .env(gitEnvironment);

  return (
    await $`git rev-parse HEAD`
      .cwd(snapshotRoot)
      .env(gitEnvironment)
      .quiet()
  ).text().trim();
}

async function main() {
  const nvim = await resolveNvim();
  const temporaryRoot = await mkdtemp(
    resolve(tmpdir(), "argiope-native-smoke-"),
  );

  try {
    const snapshotRoot = resolve(temporaryRoot, "argiope.nvim");
    const snapshotCommit = await createSnapshot(snapshotRoot);
    const environment = isolatedEnvironment(
      "argiope-native",
      resolve(temporaryRoot, "xdg"),
    );
    await ensureEnvironmentDirectories(environment);
    const smokeCommand =
      "lua local ok, err = xpcall(argiope_native_smoke, debug.traceback); " +
      "if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end";

    const result =
      await $`${nvim} --headless -n -i NONE -u ${resolve(root, "tests", "native_init.lua")} --cmd ${`set runtimepath+=${resolve(deps, "runtime")}`} --cmd ${`set runtimepath+=${resolve(deps, "nvim-treesitter")}`} --cmd ${`set runtimepath+=${resolve(deps, "nvim-treesitter", "runtime")}`} -c ${smokeCommand} -c "qa!"`
        .cwd(temporaryRoot)
        .env({
          ...environment,
          GIT_ALLOW_PROTOCOL: "file",
          GIT_CONFIG_GLOBAL: "/dev/null",
          GIT_CONFIG_NOSYSTEM: "1",
          GIT_TERMINAL_PROMPT: "0",
          ARGIOPE_NATIVE_COMMIT: snapshotCommit,
          ARGIOPE_NATIVE_SNAPSHOT: snapshotRoot,
          ARGIOPE_NATIVE_SOURCE: pathToFileURL(snapshotRoot).href,
        })
        .nothrow();
    if (result.exitCode !== 0) {
      process.exitCode = result.exitCode;
      return;
    }

    console.log("argiope: native vim.pack smoke test passed");
  } finally {
    await rm(temporaryRoot, { recursive: true, force: true });
  }
}

main().catch(reportFailure);
