// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { corsHeaders } from "../cors.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// import { createClient } from "@supabase/supabase-js";
import {
    Configuration,
    PlaidApi,
    Products,
    PlaidEnvironments,
} from "npm:plaid";
import z from "npm:zod";
import { syncTxs } from "../sync.ts";

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

        // Get the request body
        const body = await req.json();

        const schema = z.object({
            webhook_code: z.string(),
            item_id: z.string()
        });
        const { webhook_code, item_id } = schema.parse(body);

        // Get bank from item_id
        const bank = await supabaseClient.from("bank_accounts").select().eq(
            "accountId",
            item_id,
        ).single();
        if (!bank.data) {
            throw new Error(`Bank not found: ${item_id}`);
        }
        // Get user from bank
        const access_token = await supabaseClient.from("plaid_access_tokens").select().eq(
            "user",
            bank.data.user,
        ).single();

        switch (webhook_code) {
            case 'SYNC_UPDATES_AVAILABLE': {
                // Fired when new transactions data becomes available.
                await syncTxs(
                    supabaseClient,
                    bank.data.user,
                    client,
                    access_token.data?.accessToken,
                );
                break;
            }
            case 'DEFAULT_UPDATE':
            case 'INITIAL_UPDATE':
            case 'HISTORICAL_UPDATE':
                /* ignore - not needed if using sync endpoint + webhook */
                break;
            default:
                throw new Error(`Unknown webhook code: ${webhook_code}`);
        }

        return new Response(JSON.stringify({ message: "Access token saved" }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
        });
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
