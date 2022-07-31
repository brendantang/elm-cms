import { oak, postgres } from "../../deps.ts";
import { Article, fromJson, looksGood, validate } from "./article.ts";

export default function updateArticle(db: postgres.Client) {
  return async function (ctx: oak.Context) {
    try {
      const id = ctx.params.id;
      const data = await ctx.request.body().value as Article;
      const article = fromJson(data);
      if (!article) {
        ctx.response.status = 400;
        ctx.response.body = {
          message: "Could not parse form data into an article",
        };
        return;
      }

      article.id = id;
      const validation = await validate(article, db);
      if (!looksGood(validation)) {
        ctx.response.status = 422;
        ctx.response.body = { errors: validation };
      } else {
        const result = await db.queryObject<Article>(
          "UPDATE articles SET slug = $SLUG, title = $TITLE, body = $BODY, updated_at = DEFAULT WHERE id = $ID RETURNING * ",
          {
            slug: article.slug,
            title: article.title,
            body: article.body,
            id: id,
          },
        );

        const savedArticle = result.rows[0];
        if (!savedArticle) {
          ctx.response.status = 404;
          return;
        }

        ctx.response.body = { article: savedArticle };
      }
    } catch (e) {
      console.error("Error saving updated article to the database: ", e);
      ctx.response.status = 500;
    }
  };
}
