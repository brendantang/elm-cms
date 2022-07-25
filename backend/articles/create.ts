import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article } from "./article.ts";
import internalError from "../internalError.ts";

export default function createArticle(db: postgres.Client): RouteHandler {
  return async function (): Promise<Response> {
    try {
      const result = await db.queryObject<Article>(
        "INSERT INTO articles DEFAULT VALUES RETURNING * ",
      );

      const savedArticle = result.rows[0];
      if (!savedArticle) {
        return internalError();
      }

      return json({ article: savedArticle });
    } catch (e) {
      console.error("Error saving new article to the database: ", e);
      return internalError();
    }
  };
}
