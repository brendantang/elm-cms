import { logger, oak, postgres } from "./deps.ts";
import authMiddleware from "./backend/basicAuth.ts";
import indexArticles from "./backend/articles/index.ts";
import getArticle from "./backend/articles/get.ts";
import updateArticle from "./backend/articles/update.ts";
import createArticle from "./backend/articles/create.ts";
import initDatabase from "./backend/db/init.ts";
import serveFiles from "./backend/serveFiles.ts";

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

// Set up the backend admin panel routes
const admin = new oak.Router();
admin.use(authMiddleware(users));
// Set up the admin backend API routes
const api = new oak.Router();
api.get("/articles", indexArticles(db));
api.post("/articles", createArticle(db));
api.get("/articles/:id", getArticle(db));
api.post("/articles/:id", updateArticle(db));
admin.use("/api", api.routes(), api.allowedMethods());
// Set up the admin panel frontend
let indexFile: Uint8Array;
try {
  indexFile = await Deno.readFile(`${Deno.cwd()}/frontend/public/index.html`);
} catch (e) {
  throw `I ran into an error trying to read the default index file use to serve the admin panel frontend.
    Try fixing this error and starting again: \r${e}`;
}
admin.get(
  "/:filename*",
  serveFiles(`${Deno.cwd()}/frontend/public/`, indexFile),
);

// Wire together all the routes
const router = new oak.Router();
router.use("/admin", admin.routes(), admin.allowedMethods());
app.use(router.routes());

// Set up middlewares for logging
app.use(router.allowedMethods());
app.use(logger.logger);
app.use(logger.responseTime);

await app.listen({ port: PORT });
