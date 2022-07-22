import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article } from "./article.ts";

export default function indexArticles(pool: postgres.Pool): RouteHandler {
  return async function (): Promise<Response> {
    const db = await pool.connect();

    const result = await db.queryObject<Article>
      `SELECT id, slug, title, body, created_at, updated_at FROM articles ORDER BY created_at DESC`;
    const articles = result.rows;

    return json({ articles: articles });
  };
}
