import { postgres } from "../../deps.ts";

export default async function initDatabase(db: postgres.Pool) {
  const client = await db.connect();
  let schema;
  try {
    schema = await Deno.readTextFile(`${Deno.cwd()}/backend/db/schema.sql`);
  } catch (err) {
    console.error("Could not read schema file to initialize the database!");
    throw (err);
  }

  const tx = client.createTransaction("initialize_database_transaction");
  await tx.begin();
  await tx.queryArray(schema);
  await tx.commit();
}
