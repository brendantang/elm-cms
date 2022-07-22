import { file, filesWithFallback, GET, Routes, serve } from "./deps.ts";

const indexHandler = file(`${Deno.cwd()}/frontend/public/index.html`);

const routes: Routes = {
  "/api/hello": () => {
    return new Response("Hello world, from the backend server!");
  },
  "/api*": () => {
    return new Response("Backend route not found", { status: 404 });
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
