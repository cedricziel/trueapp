import { build } from "esbuild";
import { copyFileSync, mkdirSync } from "node:fs";

mkdirSync("dist", { recursive: true });
await build({
  entryPoints: ["src/index.ts"],
  outfile: "dist/index.js",
  bundle: true,
  format: "esm",
  jsx: "automatic",
  target: "es2020",
  loader: { ".svg": "dataurl" },
  external: ["react", "react-dom", "react/jsx-runtime", "lucide-react"],
});
copyFileSync("src/styles.css", "dist/styles.css");
