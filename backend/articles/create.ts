import { postgres } from "../../deps.ts";
import { Article } from "./article.ts";
import { oak } from "../../deps.ts";

export default function createArticle(db: postgres.Client) {
  return async function (ctx: oak.Context) {
    try {
      const result = await db.queryObject<Article>(
        "INSERT INTO articles DEFAULT VALUES RETURNING * ",
      );

      const savedArticle = result.rows[0];
      if (!savedArticle) {
        ctx.response.status = 500;
        return;
      }

      ctx.response.body = { article: savedArticle };
    } catch (e) {
      console.error("Error saving new article to the database: ", e);
      ctx.response.status = 500;
    }
  };
}
