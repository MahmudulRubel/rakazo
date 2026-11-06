import { execFileSync, spawn } from "node:child_process";
import path from "node:path";

function command(args, options) {
  let entry = (options?.env ?? process.env).npm_execpath;
  if (!entry && process.platform === "win32") {
    entry = path.join(
      process.env.LOCALAPPDATA ?? "",
      "npm-cache",
      "_npx",
      "3d41f72c9dd7981b",
      "node_modules",
      "pnpm",
      "bin",
      "pnpm.cjs",
    );
  }
  if (
    process.platform === "win32" &&
    entry &&
    path.isAbsolute(entry) &&
    /^pnpm\.(?:cjs|mjs|js)$/i.test(path.basename(entry))
  ) {
    return [process.execPath, [entry, ...args]];
  }
  if (process.platform === "win32") {
    return ["pnpm.cmd", args];
  }
  return ["pnpm", args];
}

export function runPnpm(args, options) {
  const [executable, argv] = command(args, options);
  return execFileSync(executable, argv, options);
}

export function spawnPnpm(args, options) {
  const [executable, argv] = command(args, options);
  return spawn(executable, argv, options);
}
