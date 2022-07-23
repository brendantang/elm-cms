import {
  file,
  filesWithFallback,
  GET,
  handleMethods,
  logger,
  postgres,
  RouteHandler,
  Routes,
  serve,
  timeoutAfter,
} from "./deps.ts";
import indexArticles from "./backend/articles/index.ts";
import getArticle from "./backend/articles/get.ts";
import updateArticle from "./backend/articles/update.ts";
import initDatabase from "./backend/db/init.ts";
import notFound from "./backend/notFound.ts";

function handleRoutingError(err: unknown) {
  console.error("Problem serving the request: ", err);
  return new Response("Sorry, that page doesn't exist.", { status: 404 });
}

const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw `I can't start up without a database connection string.
   Try starting again with an environment variable named 'DATABASE_URL'`;
}
const pool = new postgres.Pool(DATABASE_URL, 100);
await initDatabase(pool);

const routes: Routes = {
  "/api/articles": GET(indexArticles(pool)),
  "/api/articles/:id": handleMethods(
    new Map()
      .set("GET", getArticle(pool))
      .set("POST", updateArticle(pool)),
  )(notFound),
  "/api*": notFound,
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

serve(routes, [logger, timeoutAfter(10000)], {
  port: 8080,
  onError: handleRoutingError,
});
