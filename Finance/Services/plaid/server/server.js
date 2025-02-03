"use strict";
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const { Configuration, PlaidEnvironments, PlaidApi } = require("plaid");
const { getUserRecord, updateUserRecord } = require("./user_utils");
const {
  FIELD_ACCESS_TOKEN,
  FIELD_USER_ID,
  FIELD_USER_STATUS,
  FIELD_ITEM_ID,
} = require("./constants");

const APP_PORT = process.env.APP_PORT || 8000;

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(express.static("public"));

const server = app.listen(APP_PORT, function () {
  console.log(`Server is up and running at http://localhost:${APP_PORT}/`);
});


const plaidConfig = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV],
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID,
      "PLAID-SECRET": process.env.PLAID_SECRET,
      "Plaid-Version": "2020-09-14",
    },
  },
});

const plaidClient = new PlaidApi(plaidConfig);


app.get("/server/get_user_info", async (req, res, next) => {
  try {
    const currentUser = await getUserRecord();
    console.log("currentUser", currentUser);
    res.json({
      userId: currentUser["userId"],
      userStatus: currentUser["userStatus"],
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Generates a Link token to be used by the client.
 */
app.post("/server/generate_link_token", async (req, res, next) => {
  try {

    const currentUser = await getUserRecord();
    const userId = currentUser[FIELD_USER_ID];
    const createTokenResponse = await plaidClient.linkTokenCreate({
      user: {
        client_user_id: userId,
        phone_number: "+14155550123"
      },
      client_name: "iOS Demo",
      country_codes: ["US"],
      language: "en",
      products: ["auth", "transactions"],
      webhook: "https://sample-webhook-uri.com"
    });
    const data = createTokenResponse.data;
    console.log("createTokenResponse", data);
    

    
    res.json({ expiration: data.expiration, linkToken: data.link_token });
  } catch (error) {
    console.log(
      "Running into an error! Note that if you have an error when creating a " +
        "link token, it's frequently because you have the wrong client_id " +
        "or secret for the environment, or you forgot to copy over your " +
        ".env.template file to.env."
    );
    next(error);
  }
});

/**
 * Swap the public token for an access token, so we can access account info
 * in the future
 */
app.post("/server/swap_public_token", async (req, res, next) => {
  try {

    const result = await plaidClient.itemPublicTokenExchange({
      public_token: req.body.public_token,
    });
    const data = result.data;
    console.log("publicTokenExchange data", data);
    

    
    const updateData = {};
    updateData[FIELD_ACCESS_TOKEN] = data.access_token;
    updateData[FIELD_ITEM_ID] = data.item_id;
    updateData[FIELD_USER_STATUS] = "connected";
    await updateUserRecord(updateData);
    console.log("publicTokenExchange data", data);
    res.json({ success: true });

  } catch (error) {
    next(error);
  }
});


app.get("/server/simple_auth", async (req, res, next) => {
  try {
    // Get the current user and their Plaid access token
    const currentUser = await getUserRecord();
    const accessToken = currentUser[FIELD_ACCESS_TOKEN];

    // Fetch account details from Plaid
    const authResponse = await plaidClient.authGet({
      access_token: accessToken,
    });

    console.dir(authResponse.data, { depth: null });

    // Extract institution name
    const institutionName = authResponse.data.item.institution_name || "Unknown Bank";

    // Extract all accounts
    const accounts = authResponse.data.accounts;

    // Prepare an array to hold all account data
    const bankAccounts = [];

    // Fetch transactions for each account
    for (const account of accounts) {
      const accountId = account.account_id;
      const accountMask = account.mask;
      const accountName = account.name;
      const accountType = account.subtype;
      const accountBalance = account.balances.current;

      // Fetch last 10 transactions for this account
      const transactionsResponse = await plaidClient.transactionsGet({
        access_token: accessToken,
        start_date: "2024-01-01",
        end_date: new Date().toISOString().split("T")[0], // Today's date
        options: {
          account_ids: [accountId],
          count: 10, // Fetch last 10 transactions
        },
      });

      const transactions = transactionsResponse.data.transactions.map((tx) => tx.name);

      // Store the account info in the array
      bankAccounts.push({
        institutionName,
        accountMask,
        accountName,
        accountType,
        accountBalance,
        transactions,
      });
    }

    // Send all accounts' data back to iOS
    res.json({ bankAccounts });
  } catch (error) {
    console.error("Error fetching Plaid data:", error);
    next(error);
  }
});


const errorHandler = function (err, req, res, next) {
  console.error(`Your error:`);
  console.error(err);
  if (err.response?.data != null) {
    res.status(500).send(err.response.data);
  } else {
    res.status(500).send({
      error_code: "OTHER_ERROR",
      error_message: "I got some other message on the server.",
    });
  }
};
app.use(errorHandler);
