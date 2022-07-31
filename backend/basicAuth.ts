import { oak, secureCompare } from "../deps.ts";

type UsernamesAndPasswords = Record<string, string>;
function authMiddleware(users: UsernamesAndPasswords): oak.Middleware {
  return async function (
    ctx: oak.Context,
    next,
  ) {
    const authHeader = ctx.request.headers.get("authorization");
    if (authHeader) {
      const match = authHeader.match(/^Basic\s+(.*)$/);
      if (match) {
        const [username, password] = atob(match[1]).split(":");

        const expectedPassword = users[username];
        if (expectedPassword && secureCompare(password, expectedPassword)) {
          await next();
          return;
        }
      }
    }
    ctx.response.status = 401;
    ctx.response.headers.set(
      "WWW-AUTHENTICATE",
      'Basic realm="Log in to the admin panel"',
    );
    ctx.response.body = { message: "Not authorized" };
  };
}

export default authMiddleware;
