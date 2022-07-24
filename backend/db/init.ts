import { postgres } from "../../deps.ts";

export default async function initDatabase(db: postgres.Client) {
  let schema;
  try {
    schema = await Deno.readTextFile(`${Deno.cwd()}/backend/db/schema.sql`);
  } catch (err) {
    console.error("Could not read schema file to initialize the database!");
    throw (err);
  }

  const tx = db.createTransaction("initialize_database_transaction");
  await tx.begin();
  await tx.queryArray(schema);
  await tx.commit();
}
