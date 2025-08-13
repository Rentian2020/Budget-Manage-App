import {
	pgTable,
	text,
	timestamp,
	uuid,
	foreignKey,
	real,
	pgEnum,
	boolean,
	serial,
} from "drizzle-orm/pg-core";
import { usersInAuth } from "../drizzle/schema";
import type { AccountType } from "plaid";

export const plaidAccessTokens = pgTable(
	"plaid_access_tokens",
	{
		user: uuid().primaryKey().notNull(),
		accessToken: text().notNull(),
		date: timestamp({ withTimezone: true, mode: "string" }),
	},
	(table) => {
		return {
			plaidAccessTokensUserFkey: foreignKey({
				columns: [table.user],
				foreignColumns: [usersInAuth.id],
				name: "plaid_access_tokens_user_fkey",
			}).onDelete("cascade"),
		};
	},
);

export const bankTypes = pgEnum("account_type", [
	"investment",
	"credit",
	"depository",
	"loan",
	"other",
]);

export const bankAccounts = pgTable(
	"bank_accounts",
	{
		user: uuid().notNull(),
		accountId: text().primaryKey().notNull(),
		availableBalance: real(),
		currentBalance: real(),
		isoCurrencyCode: text(),
		unofficialCurrencyCode: text(),
		mask: text(),
		account_name: text(),
		officialName: text(),
		type: bankTypes().$type<AccountType>(),
		subtype: text(),
	},
	(table) => {
		return {
			bankAccountsUserFkey: foreignKey({
				columns: [table.user],
				foreignColumns: [usersInAuth.id],
				name: "bank_accounts_user_fkey",
			}).onDelete("cascade"),
		};
	},
);

export const transactions = pgTable(
	"transactions",
	{
		id: text().primaryKey().notNull(),
		account_id: text().notNull(),
		amount: real().notNull(),
		iso_currency_code: text(),
		unofficial_currency_code: text(),
		category_id: text(),
		date: timestamp({ withTimezone: true, mode: "string" }),
		merchant_name: text(),
		pending: boolean().notNull(),
		logo_url: text(),
	},
	(table) => {
		return {
			transactionsAccountIdFkey: foreignKey({
				columns: [table.account_id],
				foreignColumns: [bankAccounts.accountId],
				name: "transactions_account_id_fkey",
			}).onDelete("cascade"),
		};
	},
);
