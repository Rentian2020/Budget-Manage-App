import type { createClient } from "jsr:@supabase/supabase-js";
import type { PlaidApi } from "npm:plaid";

export async function syncTxs(
	supabase: ReturnType<typeof createClient>,
	userId: string,
	client: PlaidApi,
	access_token: string,
	cursor?: string,
) {
	const initialTxs = await client.transactionsSync({
		access_token,
		cursor,
	});

	// Map accounts to 'banks' array
	const banks = initialTxs.data.accounts.map((account) => ({
		user: userId,
		accountId: account.account_id,
		availableBalance: account.balances.available,
		currentBalance: account.balances.current,
		isoCurrencyCode: account.balances.iso_currency_code,
		unofficialCurrencyCode: account.balances.unofficial_currency_code,
		mask: account.mask,
		account_name: account.name,
		officialName: account.official_name,
		type: account.type,
		subtype: account.subtype,
	}));

	console.log(`Banks: ${banks.length}`);

	// Upsert 'banks' into 'bankAccounts' table
	await supabase
		.from("bank_accounts")
		.upsert(banks, { onConflict: "accountId" });

	// Map added transactions to 'txs' array
	const txs = initialTxs.data.added.map((tx) => ({
		id: tx.transaction_id,
		account_id: tx.account_id,
		amount: tx.amount,
		iso_currency_code: tx.iso_currency_code,
		unofficial_currency_code: tx.unofficial_currency_code,
		category_id: tx.category_id,
		date: tx.date,
		merchant_name: tx.merchant_name,
		pending: tx.pending,
		logo_url: tx.logo_url,
	}));

	// Map modified transactions to 'modified_txs' array
	const modified_txs = initialTxs.data.modified.map((tx) => ({
		id: tx.transaction_id,
		account_id: tx.account_id,
		amount: tx.amount,
		iso_currency_code: tx.iso_currency_code,
		unofficial_currency_code: tx.unofficial_currency_code,
		category_id: tx.category_id,
		date: tx.date,
		merchant_name: tx.merchant_name,
		pending: tx.pending,
		logo_url: tx.logo_url,
	}));

	// Combine 'txs' and 'modified_txs' into 'all_txs'
	const all_txs = [...txs, ...modified_txs];

	console.log(`Transactions: ${all_txs.length}`);

	// Upsert 'all_txs' into 'transactions' table
	if (all_txs.length > 0) {
		await supabase
			.from("transactions")
			.upsert(all_txs, { onConflict: "id" });
	}

	// Delete 'deleted_txs' from 'transactions' table
	const deleted_txs = initialTxs.data.removed.map((tx) => tx.transaction_id);

	if (deleted_txs.length > 0) {
		await supabase.from("transactions").delete().in("id", deleted_txs);
	}
}
