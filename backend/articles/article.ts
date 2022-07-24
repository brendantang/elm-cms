import { postgres } from "../../deps.ts";
export interface Article {
  id?: string;
  title: string;
  slug: string;
  body: string;
  created_at?: Date;
  updated_at?: Date;
}

export const newArticle: Article = {
  title: "",
  slug: "",
  body: "",
};

// Construction
export function fromJson(data: unknown): Article | null {
  if (!isArticle(data)) {
    return null;
  }
  return data;
}

export function fromFormData(data: FormData): Article | null {
  const parsedData = Array.from(data.entries()).reduce(
    (memo: Record<string, string>, [key, value]) => {
      if (typeof (value) === "string") {
        memo[key] = value;
      }
      return memo;
    },
    {},
  );
  if (isArticle(parsedData)) {
    return parsedData;
  }
  return null;
}

export function isArticle(_object: unknown): _object is Article {
  return true;
}

// Validation

export async function validate(
  article: Article,
  db: postgres.Client,
): Promise<ValidationResult> {
  const result = { title: [], slug: [] } as ValidationResult;
  // Validate that slug is present
  if (article.slug.length < 1) {
    result.slug.push("can't be blank");
  } else {
    // If present, validate that slug is not taken
    const taken = await takenSlugs(article.id || "", db);
    if (taken.includes(article.slug)) {
      result.slug.push("is taken");
    }
  }
  // Validate that title is present
  if (article.title.length < 1) {
    result.title.push("can't be blank");
  }
  return result;
}

export function looksGood(validation: ValidationResult): boolean {
  return validation.title.length === 0 && validation.slug.length === 0;
}

export interface ValidationResult {
  title: string[];
  slug: string[];
}

export async function takenSlugs(
  articleId: string,
  db: postgres.Client,
): Promise<string[]> {
  let queryString = "select slug from articles";
  if (articleId.length > 0) {
    queryString = queryString + " where id != $ID";
  }
  const result = await db.queryObject<{ slug: string }>(
    queryString,
    { id: articleId },
  );
  return result.rows.map((row) => {
    return row.slug;
  });
}
