import { postgres } from "../../deps.ts";

export default async function initDatabase(db: postgres.Client) {
  const schema = `
CREATE TABLE IF NOT EXISTS articles (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      slug text UNIQUE,
      title text,
      body text,
      metadata jsonb DEFAULT '{}'::jsonb,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
)
  `;
  const tx = db.createTransaction("initialize_database_transaction");
  await tx.begin();
  await tx.queryArray(schema);
  await tx.commit();
}
