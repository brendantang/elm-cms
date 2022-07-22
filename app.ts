import {
  file,
  filesWithFallback,
  GET,
  logger,
  postgres,
  Routes,
  serve,
} from "./deps.ts";
import indexArticles from "./backend/articles/index.ts";
import getArticle from "./backend/articles/get.ts";
import initDatabase from "./backend/db/init.ts";

function handleRoutingError(err) {
  console.error("Problem serving the request: ", err);
  return new Response("Sorry, that page doesn't exist.", { status: 404 });
}

const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw `I can't start up without a database connection string.
   Try starting again with an environment variable named 'DATABASE_URL'`;
}
const pool = new postgres.Pool(DATABASE_URL, 20);
await initDatabase(pool);

const routes: Routes = {
  "/api/articles": GET(indexArticles(pool)),
  "/api/articles/:id": GET(getArticle(pool)),
  "/api*": () => {
    return new Response("Backend route not found", { status: 404 });
  },
  "/admin/:filename*": GET(
    filesWithFallback(
      `${Deno.cwd()}/frontend/public/`,
      "filename",
      file(`${Deno.cwd()}/frontend/public/index.html`),
    ),
  ),
  "/": GET(
    function () {
      return new Response("TODO: Serve content");
    },
  ),
};
console.log(routes);
serve(routes, [logger], { port: 8080, onError: handleRoutingError });
