import start from "./mod.ts";

// Initialize settings with environment variables

// HTTP port to serve the application on
const PORT = Number(Deno.env.get("PORT"));

// PostgreSQL database connection string
const DATABASE_URL = Deno.env.get("DATABASE_URL");
if (!DATABASE_URL) {
  throw "I can't start up without a database connection string. Try again with an environment variable 'DATABASE_URL'";
}

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

start({ port: PORT, users: users, databaseUrl: DATABASE_URL });
