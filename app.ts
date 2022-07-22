import {
  file,
  filesWithFallback,
  GET,
  postgres,
  Routes,
  serve,
} from "./deps.ts";
import helloHandler from "./backend/hello.ts";
import init from "./backend/db/init.ts";

const indexHandler = file(`${Deno.cwd()}/frontend/public/index.html`);

const routes: Routes = {
  "/api/hello": GET(helloHandler),
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

const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw `I can't start up without a database connection string.
   Try starting again with an environment variable named 'DATABASE_URL'`;
}
const pool = new postgres.Pool(DATABASE_URL, 20);
const client = await pool.connect();

await init(client);
serve(routes);
