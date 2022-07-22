import { file, filesWithFallback, GET, Routes, serve } from "./deps.ts";

const indexHandler = file(`${Deno.cwd()}/frontend/public/index.html`);

const routes: Routes = {
  "/api": () => {
    return new Response("TODO: serve backend");
  },
  "/:filename*": GET(
    filesWithFallback(
      `${Deno.cwd()}/frontend/public/`,
      "filename",
      indexHandler,
    ),
  ),
};

serve(routes);
