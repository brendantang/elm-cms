import { eta, oak, postgres } from "../../deps.ts";
import { Article } from "./article.ts";

export default function indexPublicArticles(
  db: postgres.Client,
  template: string,
) {
  return async function (ctx: oak.Context) {
    const page = Number(ctx.request.url.searchParams.get("page") || 1);
    const perPage = Number(
      ctx.request.url.searchParams.get("perPage") || 10,
    );
    const offset = (page - 1) * perPage;
    try {
      const result = await db.queryObject<Article>
        `SELECT id, slug, title, created_at, updated_at 
        FROM articles 
        ORDER BY created_at DESC
        LIMIT ${perPage}
        OFFSET ${offset}`;
      const articles = result.rows;
      ctx.response.body = await eta.render(template, { articles: articles });
    } catch (e) {
      console.error("Error querying the database: ", e);
      ctx.response.status = 500;
    }
  };
}
