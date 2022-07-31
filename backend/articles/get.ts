import { oak, postgres } from "../../deps.ts";
import { Article } from "./article.ts";

export default function getArticle(db: postgres.Client) {
  return async function (ctx: oak.Context) {
    try {
      const id = ctx.params.id;
      const result = await db.queryObject<Article>(
        "SELECT id, slug, title, body, created_at, updated_at FROM articles WHERE id = $ID",
        { id: id },
      );
      const article = result.rows[0];
      ctx.response.body = { article: article };
    } catch (e) {
      console.error("Error querying the database: ", e);
      ctx.response.status = 404;
    }
  };
}
