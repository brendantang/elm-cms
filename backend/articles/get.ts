import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article } from "./article.ts";
import internalError from "../internalError.ts";

export default function getArticle(db: postgres.Client): RouteHandler {
  return async function (_req, _connInfo, params): Promise<Response> {
    try {
      const id = params["id"];
      const result = await db.queryObject<Article>(
        "SELECT id, slug, title, body, created_at, updated_at FROM articles WHERE id = $ID",
        { id: id },
      );

      const article = result.rows[0];

      return json({ article: article });
    } catch (e) {
      console.error("Error querying the database: ", e);
      return internalError();
    }
  };
}
