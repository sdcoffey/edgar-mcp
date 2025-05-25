import path from "node:path";
import url from "node:url";

const dirname = url.fileURLToPath(new URL(".", import.meta.url));
const preactCompatPlugin = {
  name: "preact-compat",
  setup(build) {
    const preact = path.join(
      dirname,
      "node_modules",
      "preact",
      "compat",
      "dist",
      "compat.module.js",
    );

    build.onResolve({ filter: /^(react-dom|react)$/ }, () => {
      return { path: preact };
    });
  },
};

export default preactCompatPlugin;
