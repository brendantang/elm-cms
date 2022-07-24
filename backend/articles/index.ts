import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article } from "./article.ts";
import internalError from "../internalError.ts";

export default function indexArticles(db: postgres.Client): RouteHandler {
  return async function (): Promise<Response> {
    try {
      const result = await db.queryObject<Article>
        `SELECT id, slug, title, created_at, updated_at FROM articles ORDER BY created_at DESC`;
      const articles = result.rows;

      return json({ articles: articles });
    } catch (e) {
      console.error("Error querying the database: ", e);
      return internalError();
    }
  };
}
