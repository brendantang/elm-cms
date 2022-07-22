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
