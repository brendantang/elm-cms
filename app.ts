import { logger, oak, postgres } from "./deps.ts";
import authMiddleware from "./backend/basicAuth.ts";
import indexArticles from "./backend/articles/index.ts";
import getArticle from "./backend/articles/get.ts";
import updateArticle from "./backend/articles/update.ts";
import createArticle from "./backend/articles/create.ts";
import initDatabase from "./backend/db/init.ts";

// Initialize settings with environment variables

// HTTP port to serve the application on
const PORT = Number(Deno.env.get("PORT") || "8080");

// PostgreSQL database connection string
const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw `I can't start up without a database connection string.
   Try starting again with an environment variable named 'DATABASE_URL'`;
}
const db = new postgres.Client(DATABASE_URL);
await initDatabase(db);

// Basic auth credentials to access the admin panel
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

// Initialize the web application
const app = new oak.Application();

// Set up the application routes

const api = new oak.Router();
api.use(authMiddleware(users));
api.get("/articles", indexArticles(db));
api.post("/articles", createArticle(db));
api.get("/articles/:id", getArticle(db));
api.post("/articles/:id", updateArticle(db));

const router = new oak.Router();
router.use("/api", api.routes(), api.allowedMethods());

//router.get("/admin/:filename*", handleFrontend);

// Set up middlewares for logging
app.use(router.routes());
app.use(router.allowedMethods());
app.use(logger.logger);
app.use(logger.responseTime);

await app.listen({ port: PORT });
