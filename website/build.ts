import { $ } from "bun";
import { existsSync, cpSync } from "fs";
import { join } from "path";

const isWatch = process.argv.includes("--watch");
const isProduction = process.env.NODE_ENV === "production";

const rootDir = import.meta.dir;
const srcDir = join(rootDir, "src");
const distDir = join(rootDir, "dist");

async function buildCSS(): Promise<void> {
  const start = performance.now();
  await $`bunx @tailwindcss/cli -i ${join(srcDir, "styles/main.css")} -o ${join(distDir, "styles.css")} ${isProduction ? "--minify" : ""}`.quiet();
  const elapsed = (performance.now() - start).toFixed(0);
  console.log(`  CSS: ${elapsed}ms`);
}

async function buildJS(): Promise<void> {
  const start = performance.now();
  const result = await Bun.build({
    entrypoints: [join(srcDir, "index.tsx")],
    outdir: distDir,
    format: "esm",
    target: "browser",
    minify: isProduction,
  });
  if (!result.success) {
    console.error("JS build failed:");
    for (const log of result.logs) {
      console.error(log);
    }
    process.exit(1);
  }
  const elapsed = (performance.now() - start).toFixed(0);
  console.log(`  JS:  ${elapsed}ms`);
}

async function copyAssets(): Promise<void> {
  const start = performance.now();

  // Copy learn-swift.html
  const learnSwiftSrc = join(srcDir, "learn-swift.html");
  if (existsSync(learnSwiftSrc)) {
    await Bun.write(join(distDir, "learn-swift.html"), Bun.file(learnSwiftSrc));
  }

  // Copy index.html
  const indexHtmlSrc = join(rootDir, "index.html");
  if (existsSync(indexHtmlSrc)) {
    await Bun.write(join(distDir, "index.html"), Bun.file(indexHtmlSrc));
  }

  // Copy screenshots/ directory if it exists
  const screenshotsDir = join(rootDir, "screenshots");
  if (existsSync(screenshotsDir)) {
    cpSync(screenshotsDir, join(distDir, "screenshots"), { recursive: true });
  }

  // Copy assets/ directory from repo root (for logo.svg, screenshots, etc.)
  const assetsDir = join(rootDir, "..", "assets");
  if (existsSync(assetsDir)) {
    cpSync(assetsDir, join(distDir, "assets"), { recursive: true });
  }

  const elapsed = (performance.now() - start).toFixed(0);
  console.log(`  Assets: ${elapsed}ms`);
}

async function build(): Promise<void> {
  const start = performance.now();
  console.log(`\nBuilding... (${isProduction ? "production" : "development"})`);

  // Ensure dist directory exists
  await $`mkdir -p ${distDir}`.quiet();

  // Run CSS, JS, and asset copy in parallel
  await Promise.all([buildCSS(), buildJS(), copyAssets()]);

  const elapsed = (performance.now() - start).toFixed(0);
  console.log(`\nDone in ${elapsed}ms\n`);
}

await build();

if (isWatch) {
  console.log(
    "Watch mode is not yet implemented. Run the build command again after making changes.",
  );
}
