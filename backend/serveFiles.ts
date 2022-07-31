import { oak } from "../deps.ts";

export default function serveFiles(
  rootPath: string,
  indexFile: Uint8Array,
): oak.Middleware {
  return async function (ctx: oak.Context) {
    let file;
    try {
      const filepath = rootPath + ctx.params.filename;
      file = await Deno.readFile(filepath);
      ctx.response.body = file;
    } catch (e) {
      ctx.response.body = indexFile;
    }
  };
}
