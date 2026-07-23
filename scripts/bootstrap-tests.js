import { $ } from "bun";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { deps, reportFailure, requireCommand, root } from "./runtime.js";

const dependencies = {
  plenary: {
    name: "plenary.nvim",
    url: "https://github.com/nvim-lua/plenary.nvim.git",
    revision: "74b06c6c75e4eeb3108ec01852001636d85a932b",
    probe: "plugin/plenary.vim",
  },
  nvimTreesitter: {
    // Keep a fixed monolithic query snapshot for deterministic regression
    // tests. CI separately runs the suite against the current
    // neovim-treesitter fork and distributed query registry.
    name: "nvim-treesitter",
    url: "https://github.com/nvim-treesitter/nvim-treesitter.git",
    revision: "957f86ae3f049ab6681ed64c05b05768fcaed0d2",
    probe: "runtime/queries/javascript/highlights.scm",
  },
  javascript: {
    name: "tree-sitter-javascript",
    url: "https://github.com/tree-sitter/tree-sitter-javascript.git",
    revision: "58404d8cf191d69f2674a8fd507bd5776f46cb11",
    probe: "src/grammar.json",
  },
  html: {
    name: "tree-sitter-html",
    url: "https://github.com/tree-sitter/tree-sitter-html.git",
    revision: "73a3947324f6efddf9e17c0ea58d454843590cc0",
    probe: "src/grammar.json",
  },
  css: {
    name: "tree-sitter-css",
    url: "https://github.com/tree-sitter/tree-sitter-css.git",
    revision: "dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f",
    probe: "src/grammar.json",
  },
  markdown: {
    name: "tree-sitter-markdown",
    url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown.git",
    revision: "808e105aff82bc7cbc1587384dab71151b62182f",
    probe: "tree-sitter-markdown/src/grammar.json",
  },
};

const parsers = [
  { language: "javascript", dependency: dependencies.javascript },
  { language: "html", dependency: dependencies.html },
  { language: "css", dependency: dependencies.css },
  {
    language: "markdown",
    dependency: dependencies.markdown,
    sourceDirectory: "tree-sitter-markdown",
  },
  {
    language: "markdown_inline",
    dependency: dependencies.markdown,
    sourceDirectory: "tree-sitter-markdown-inline",
  },
];

async function checkoutDependency(dependency) {
  const destination = resolve(deps, dependency.name);
  if (!existsSync(destination)) {
    await $`git clone --filter=blob:none --no-checkout ${dependency.url} ${destination}`.cwd(
      root,
    );
  } else if (!existsSync(resolve(destination, ".git"))) {
    throw new Error(
      `argiope: ${destination} exists but is not a git checkout`,
    );
  }

  const current = (
    await $`git -C ${destination} rev-parse HEAD`.quiet().nothrow()
  )
    .text()
    .trim();
  const status = (
    await $`git -C ${destination} status --porcelain`.quiet()
  )
    .text()
    .trim();

  if (
    current === dependency.revision &&
    existsSync(resolve(destination, dependency.probe))
  ) {
    if (status) {
      throw new Error(
        `argiope: ${destination} has local changes; clean or replace it before bootstrapping`,
      );
    }
    return;
  }

  if (status && existsSync(resolve(destination, dependency.probe))) {
    throw new Error(
      `argiope: ${destination} has local changes; clean or replace it before changing revisions`,
    );
  }

  if (current !== dependency.revision) {
    const commit = `${dependency.revision}^{commit}`;
    const present = await $`git -C ${destination} cat-file -e ${commit}`
      .quiet()
      .nothrow();
    if (present.exitCode !== 0) {
      await $`git -C ${destination} fetch --depth=1 origin ${dependency.revision}`;
    }
  }
  await $`git -C ${destination} checkout --detach ${dependency.revision}`;
}

async function buildParser(parser) {
  const parserDirectory = resolve(deps, parser.dependency.name);
  const sourceDirectory = parser.sourceDirectory
    ? resolve(parserDirectory, parser.sourceDirectory)
    : parserDirectory;
  const output = resolve(deps, "runtime", "parser", `${parser.language}.so`);
  const marker = resolve(
    deps,
    "runtime",
    "parser-info",
    `${parser.language}.revision`,
  );
  const installedRevision = existsSync(marker)
    ? (await Bun.file(marker).text()).trim()
    : "";

  if (existsSync(output) && installedRevision === parser.dependency.revision) {
    return;
  }

  console.log(`argiope: building ${parser.language} parser`);
  await $`tree-sitter build -o ${output}`.cwd(sourceDirectory);
  await Bun.write(marker, `${parser.dependency.revision}\n`);
}

async function main() {
  await requireCommand("git", "to bootstrap tests");
  await requireCommand("tree-sitter", "to build Tree-sitter parsers");
  await requireCommand("cc", "to build Tree-sitter parsers");

  await $`mkdir -p ${deps} ${resolve(deps, "xdg", "cache")} ${resolve(deps, "runtime", "parser")} ${resolve(deps, "runtime", "parser-info")}`;

  for (const dependency of Object.values(dependencies)) {
    await checkoutDependency(dependency);
  }
  for (const parser of parsers) {
    await buildParser(parser);
  }

  console.log("argiope: test dependencies are ready");
}

main().catch(reportFailure);
