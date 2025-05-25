/* biome-ignore */

import chokidar from "chokidar";
import http from "http";
import path from "path";
import yargs from "yargs";

import { context } from "esbuild";
import { glob } from "glob";

const clients = [];
const environment = process.env.RAILS_ENV || "development";

const argv = yargs(process.argv.slice(2)).options({
  watch: { type: "boolean", default: false },
  minify: { type: "boolean", default: environment === "production" },
  sourcemap: { type: "boolean", default: environment === "development" },
  treeshake: { type: "boolean", default: true },
}).argv;

const watchMode = environment === "development" && argv.watch;

const watchGlob = [
  "app/views/**/*.erb",
  "app/components/**/*.rb",
  "app/components/**/*",
  "app/helpers/**/*.rb",
  "config/locales/**/*.yml",
  "app/javascript/**/*.tsx",
  "app/javascript/**/*.ts",
  "app/assets/stylesheets/**/*.css",
];
(async () => {
  let entryPoints = await glob("./app/javascript/**/*.{ts,tsx}", {
    ignore: {
      ignored: (p) => /^.*\.test\.tsx?$/.test(p.name),
    },
  });
  entryPoints = entryPoints.concat(await glob("./app/components/*.ts"));

  const buildContext = await context({
    entryPoints,
    bundle: false,
    format: "esm",
    sourcemap: argv.sourcemap,
    metafile: true,
    outdir: "app/assets/builds",
    publicPath: "assets",
    minify: argv.minify,
    define: {
      "process.env.NODE_ENV": `"${environment}"`,
    },
    loader: {
      ".svg": "dataurl",
    },
    treeShaking: argv.treeshake,
  });

  await buildContext.rebuild();

  if (watchMode) {
    console.log("running in watch mode");
    const watcher = chokidar.watch(watchGlob);

    const handler = (event) => async (filepath) => {
      if (event !== "change") {
        return;
      }

      console.log(filepath, "changed, rebuilding");

      if ([".js", ".ts", ".tsx"].includes(path.extname(filepath))) {
        try {
          await buildContext.rebuild();
        } catch (e) {
          console.error("JS build FAILED", e);
        }
      }

      setTimeout(() => {
        clients.forEach((c) => c.write("data: reload\n\n"));
        clients.length = 0;
      }, 250);
    };

    watcher
      .on("add", handler("add"))
      .on("change", handler("change"))
      .on("unlink", handler("unlink"));

    const server = http
      .createServer((req, res) => {
        return clients.push(
          res.writeHead(200, {
            "Content-Type": "text/event-stream",
            "Cache-Control": "no-cache",
            "Access-Control-Allow-Origin": "*",
            Connection: "keep-alive",
          }),
        );
      })
      .listen(8082);

    server.on("close", () => {
      buildContext.dispose();
    });
  } else {
    await buildContext.dispose();
  }
})();
