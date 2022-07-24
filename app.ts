import {
  basicAuth,
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
import unauthorized from "./backend/unauthorized.ts";

function handleRoutingError(err: unknown) {
  console.error("Problem serving the request: ", err);
  return new Response("Sorry, that page doesn't exist.", { status: 404 });
}

const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw `I can't start up without a database connection string.
   Try starting again with an environment variable named 'DATABASE_URL'`;
}
const db = new postgres.Client(DATABASE_URL);
await initDatabase(db);

const [USERNAME, PASSWORD] = [
  Deno.env.get("BASIC_AUTH_USERNAME"),
  Deno.env.get("BASIC_AUTH_PASSWORD"),
];
if (!USERNAME || !PASSWORD) {
  throw `I can't start up without a username and password to authenticate backend requests.
    Try starting again with environment variables 'BASIC_AUTH_USERNAME' AND 'BASIC_AUTH_PASSWORD'`;
}
const users = {} as Record<string, string>;
users[USERNAME] = PASSWORD;

const authMiddleware = basicAuth(users, unauthorized);

const routes: Routes = {
  "/api/articles": GET(indexArticles(db)),
  "/api/articles/:id": handleMethods(
    new Map()
      .set("GET", getArticle(db))
      .set("POST", authMiddleware(updateArticle(db))),
  )(notFound),
  "/api*": notFound,
  "/admin/:filename*": authMiddleware(GET(
    filesWithFallback(
      `${Deno.cwd()}/frontend/public/`,
      "filename",
      file(`${Deno.cwd()}/frontend/public/index.html`),
    ),
  )),
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
