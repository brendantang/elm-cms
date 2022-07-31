import { oak, postgres } from "../../deps.ts";
import { Article } from "./article.ts";

export default function getArticle(db: postgres.Client) {
  return async function (ctx: oak.Context) {
    try {
      const slug = ctx.params.slug;
      const result = await db.queryObject<Article>(
        "SELECT id, slug, title, body, created_at, updated_at FROM articles WHERE slug = $SLUG",
        { slug: slug },
      );
      const article = result.rows[0];
      if (!article) {
        ctx.response.status = 404;
        ctx.response.body = { message: "Article not found" };
        return;
      }
      ctx.response.body = { article: article };
    } catch (e) {
      console.error("Error querying the database: ", e);
      ctx.response.status = 404;
    }
  };
}
