import { oak, postgres } from "../../deps.ts";
import { Article } from "./article.ts";

export default function indexArticles(db: postgres.Client) {
  return async function (ctx: oak.Context) {
    try {
      const result = await db.queryObject<Article>
        `SELECT id, slug, title, created_at, updated_at FROM articles ORDER BY created_at DESC`;
      const articles = result.rows;

      ctx.response.body = { articles: articles };
    } catch (e) {
      console.error("Error querying the database: ", e);
      ctx.response.status = 500;
    }
  };
}
