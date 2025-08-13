import { drizzle } from "drizzle-orm/postgres-js";
import * as schema from "../drizzle/schema";
import * as relations from "../drizzle/relations";

// Merge schema and relations
const merged = { ...schema, ...relations };

export const db = drizzle(process.env.DATABASE_URL ?? "", { schema: merged });
