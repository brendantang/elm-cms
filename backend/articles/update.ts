import { json, postgres, RouteHandler } from "../../deps.ts";
import { Article, fromJson, looksGood, validate } from "./article.ts";
import internalError from "../internalError.ts";
import notFound from "../notFound.ts";

export default function updateArticle(db: postgres.Client): RouteHandler {
  return async function (req, _connInfo, params): Promise<Response> {
    try {
      const id = params["id"];
      const data = await req.json() as Article;
      const article = fromJson(data);
      if (!article) {
        return json({ message: "Could not parse form data into an article" }, {
          status: 400,
        });
      }

      article.id = id;
      const validation = await validate(article, db);
      if (!looksGood(validation)) {
        return json({
          errors: validation,
        }, { status: 422 });
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
          return notFound();
        }

        return json({ article: savedArticle });
      }
    } catch (e) {
      console.error("Error saving updated article to the database: ", e);
      return internalError();
    }
  };
}
