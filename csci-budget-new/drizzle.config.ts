import "dotenv/config";
import { defineConfig } from "drizzle-kit";

export default defineConfig({
	out: "./drizzle",
	schema: "./db/schema.ts",
	dialect: "postgresql",
	schemaFilter: ["public"],
	dbCredentials: {
		host: "127.0.0.1", //process.env.DATABASE_HOST ?? "",
		port: 54322,
		database: process.env.DATABASE_DB ?? "",
		user: "postgres", // process.env.DATABASE_USER ?? "",
		password: "postgres", //process.env.DATABASE_PASSWORD ?? "",
	},
});
