// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { corsHeaders } from "../cors.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
	Configuration,
	PlaidApi,
	Products,
	PlaidEnvironments,
	type LinkTokenCreateRequest,
} from "npm:plaid";

// PLAID_PRODUCTS is a comma-separated list of products to use when initializing
// Link. Note that this list must contain 'assets' in order for the app to be
// able to create and retrieve asset reports.
const PLAID_PRODUCTS = (
	Deno.env.get("PLAID_PRODUCTS") || Products.Transactions
).split(",");

// PLAID_COUNTRY_CODES is a comma-separated list of countries for which users
// will be able to select institutions from.
const PLAID_COUNTRY_CODES = (Deno.env.get("PLAID_COUNTRY_CODES") || "US").split(
	",",
);

// Parameters used for the OAuth redirect Link flow.
//
// Set PLAID_REDIRECT_URI to 'http://localhost:3000'
// The OAuth redirect flow requires an endpoint on the developer's website
// that the bank website should redirect to. You will need to configure
// this redirect URI for your client ID through the Plaid developer dashboard
// at https://dashboard.plaid.com/team/api.
const PLAID_REDIRECT_URI = Deno.env.get("PLAID_REDIRECT_URI") || "";

Deno.serve(async (req: Request) => {
	// This is needed if you're planning to invoke your function from a browser.
	if (req.method === "OPTIONS") {
		return new Response("ok", { headers: corsHeaders });
	}

	// if (req.method !== "GET") {
	// 	return new Response("Method not allowed", {
	// 		status: 405,
	// 		headers: corsHeaders,
	// 	});
	// }

	try {
		const configuration = new Configuration({
			basePath: PlaidEnvironments.sandbox,
			baseOptions: {
				headers: {
					"PLAID-CLIENT-ID": Deno.env.get("PLAID_CLIENT_ID") ?? "",
					"PLAID-SECRET": Deno.env.get("PLAID_SECRET") ?? "",
				},
			},
		});

		console.log(`Using client ID: ${Deno.env.get("PLAID_CLIENT_ID")}`);

		const client = new PlaidApi(configuration);

		// Create a Supabase client with the Auth context of the logged in user.
		const supabaseClient = createClient(
			// Supabase API URL - env var exported by default.
			Deno.env.get("SUPABASE_URL") ?? "",
			// Supabase API ANON KEY - env var exported by default.
			Deno.env.get("SUPABASE_ANON_KEY") ?? "",
			// Create client with Auth context of the user that called the function.
			// This way your row-level-security (RLS) policies are applied.
			{
				global: {
					headers: {
						Authorization: req.headers.get("Authorization"),
					},
				},
			},
		);

		// First get the token from the Authorization header
		const token = req.headers.get("Authorization")?.replace("Bearer ", "");

		// Now we can get the session or user object
		const {
			data: { user },
		} = await supabaseClient.auth.getUser(token);

		// Check if the user is authenticated
		if (!user) {
			throw new Error("User not authenticated");
		}

		console.log(`User authenticated: ${user.email}`);

		const configs: LinkTokenCreateRequest = {
			user: {
				// This should correspond to a unique id for the current user.
				client_user_id: "user-id",
			},
			client_name: "Plaid Quickstart",
			products: PLAID_PRODUCTS,
			country_codes: PLAID_COUNTRY_CODES,
			language: "en",
			redirect_uri:
				PLAID_REDIRECT_URI === "" ? undefined : PLAID_REDIRECT_URI,
			webhook: "https://dkgrbhsnhubowckwzdot.supabase.co/functions/v1/sync"
		};

		// const craEnumValues = Object.values(CraCheckReportProduct);
		// if (PLAID_PRODUCTS.some((product) => craEnumValues.includes(product))) {
		// 	configs.user_token = USER_TOKEN;
		// 	configs.cra_options = {
		// 		days_requested: 60,
		// 	};
		// 	configs.consumer_report_permissible_purpose =
		// 		"ACCOUNT_REVIEW_CREDIT";
		// }
		const createTokenResponse: {
			data?: {
				link_token?: string;
			};
		} = await client.linkTokenCreate(configs);

		return new Response(
			JSON.stringify({ token: createTokenResponse.data?.link_token }),
			{
				headers: { ...corsHeaders, "Content-Type": "application/json" },
				status: 200,
			},
		);
	} catch (error) {
		if (error instanceof Error) {
			console.log(error);
			return new Response(JSON.stringify({ error: error.message }), {
				headers: { ...corsHeaders, "Content-Type": "application/json" },
				status: 400,
			});
		}
	}
});

// To invoke:
// curl -i --location --request POST 'http://localhost:54321/functions/v1/' \
//   --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
//   --header 'Content-Type: application/json' \
//   --data '{"name":"Functions"}'
