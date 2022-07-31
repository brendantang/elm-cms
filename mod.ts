import { logger, oak, postgres } from "./deps.ts";
import errorHandler from "./backend/errorHandler.ts";
import { authMiddleware, UsernamesAndPasswords } from "./backend/basicAuth.ts";
import indexArticles from "./backend/articles/index.ts";
import getArticle from "./backend/articles/get.ts";
import updateArticle from "./backend/articles/update.ts";
import createArticle from "./backend/articles/create.ts";
import initDatabase from "./backend/db/init.ts";
import indexPublicArticles from "./backend/articles/indexPublic.ts";
import getPublicArticle from "./backend/articles/getPublic.ts";

const moduleUrl =
  "https://raw.githubusercontent.com/brendantang/elm-cms/main/frontend/public/";
interface Configuration {
  port?: number;
  databaseUrl: string;
  users: UsernamesAndPasswords;
}
export default async function start(cfg: Configuration) {
  // Initialize database connection
  let db: postgres.Client;
  try {
    db = new postgres.Client(cfg.databaseUrl);
    await initDatabase(db);
  } catch (e) {
    throw `Error trying to initialize the database: ${e}`;
  }

  // Initialize the web application
  const app = new oak.Application();
  app.use(errorHandler);

  // Set up the backend admin panel routes
  const admin = new oak.Router();
  admin.use(authMiddleware(cfg.users));
  // Set up the admin backend API routes
  const api = new oak.Router();
  api.get("/articles", indexArticles(db));
  api.post("/articles", createArticle(db));
  api.get("/articles/:id", getArticle(db));
  api.post("/articles/:id", updateArticle(db));
  admin.use("/api", api.routes(), api.allowedMethods());
  // Set up the admin panel frontend
  let indexFile: string;
  let cssFile: string;
  let compiledElm: string;
  try {
    [indexFile, cssFile, compiledElm] = await Promise.all(
      ["index.html", "spinner.css", "main.js"]
        .map(async (filename) => {
          if (Deno.env.get("CMS_ENV") == "development") {
            return await Deno.readTextFile("./frontend/public/" + filename);
          }
          return await fetch(moduleUrl + filename).then(
            (response) => {
              if (response.status !== 200) {
                console.log(response);
                throw `Could not fetch static assets for the admin panel. Got response code ${response.status} trying to fetch ${response.url}`;
              }
              return response.text();
            },
          );
        }),
    );
  } catch (e) {
    throw `I ran into an error trying to load static assets for the admin panel. Try fixing this error and starting again: ${e}`;
  }
  admin.get("/main.js", (ctx) => ctx.response.body = compiledElm)
    .get("/spinner.css", (ctx) => ctx.response.body = cssFile)
    .get("/:filename*", (ctx) => {
      ctx.response.body = indexFile;
    });
  // Set up routes to serve published content
  const content = new oak.Router();
  const contentRoutes = await Promise.all([
    { route: "/", handler: indexPublicArticles, templateName: "index" },
    {
      route: "/articles/:slug",
      handler: getPublicArticle,
      templateName: "show",
    },
  ].map(async ({ route, handler, templateName }) => {
    const templatePath = `${Deno.cwd()}/templates/${templateName}.html`;
    let template: string;
    try {
      template = await Deno.readTextFile(templatePath);
    } catch (e) {
      throw `error loading a template (expected a template file at '${templatePath}' to serve the route '${route}'): ${e}`;
    }
    return { route: route, handler: handler, template: template };
  }));
  contentRoutes.map(({ route, handler, template }) => {
    content.get(route, handler(db, template));
  });

  // Wire together all the routes
  const router = new oak.Router();
  router.use("/admin", admin.routes(), admin.allowedMethods());
  router.use(content.routes(), content.allowedMethods());
  app.use(router.routes(), router.allowedMethods());

  // Set up middlewares for logging
  app.use(router.allowedMethods());
  app.use(logger.logger);
  app.use(logger.responseTime);

  app.addEventListener("listen", ({ hostname, port, serverType }) => {
    console.log(
      `Listening on ${hostname}:${port} using HTTP server: ${serverType}`,
    );
  });

  await app.listen({ port: cfg.port || 8080 });
}
