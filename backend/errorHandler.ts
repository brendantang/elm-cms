import { oak } from "../deps.ts";

// Error handler middleware
export default async function errorHandler(
  ctx: oak.Context,
  next: oak.Middleware,
) {
  try {
    await next();
  } catch (e) {
    if (e instanceof oak.HttpError) {
      // deno-lint-ignore no-explicit-any
      ctx.response.status = e.status as any;
      if (e.expose) {
        ctx.response.body = `<!DOCTYPE html>
            <html>
              <body>
                <h1>${e.status} - ${e.message}</h1>
              </body>
            </html>`;
      } else {
        ctx.response.body = `<!DOCTYPE html>
            <html>
              <body>
                <h1>${e.status} - ${oak.Status[e.status]}</h1>
              </body>
            </html>`;
      }
    } else if (e instanceof Error) {
      ctx.response.status = 500;
      ctx.response.body = `<!DOCTYPE html>
            <html>
              <body>
                <h1>500 - Internal Server Error</h1>
              </body>
            </html>`;
      console.error("Unhandled Error:", e.message);
      console.error(e.stack);
    }
  }
}
