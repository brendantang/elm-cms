import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article, fromJson } from "./article.ts";

export default function updateArticle(pool: postgres.Pool): RouteHandler {
  return async function (req, _connInfo, params): Promise<Response> {
    const db = await pool.connect();
    const id = params["id"];
    const data = await req.json() as Article;
    const article = fromJson(data);
    if (!article) {
      return json({ message: "Could not parse form data into an article" }, {
        status: 422,
      });
    }
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

    return json({ article: savedArticle });
  };
}
