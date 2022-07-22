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
