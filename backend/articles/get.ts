import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article } from "./article.ts";

export default function getArticle(pool: postgres.Pool): RouteHandler {
  return async function (_req, _connInfo, params): Promise<Response> {
    const db = await pool.connect();
    const id = params["id"];
    const result = await db.queryObject<Article>(
      "SELECT id, slug, title, body, created_at, updated_at FROM articles WHERE id = $ID",
      { id: id },
    );

    const article = result.rows[0];

    return json({ article: article });
  };
}