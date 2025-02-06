"use strict";
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");
const admin = require("firebase-admin");
const path = require("path");
const { Configuration, PlaidEnvironments, PlaidApi } = require("plaid");
const { updateUserRecord } = require("./user_utils");
const {
  FIELD_ACCESS_TOKEN,
  FIELD_USER_ID,
  FIELD_USER_STATUS,
  FIELD_ITEM_ID,
} = require("./constants");

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(path.join(__dirname, "serviceAccountKey.json")),
});



// Express App Configuration
const APP_PORT = process.env.APP_PORT || 8000;
const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(express.static("public"));

const server = app.listen(APP_PORT, function () {
  console.log(`Server is running at http://localhost:${APP_PORT}/`);
});

// Plaid API Configuration
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

async function authenticate(req, res, next) {
  const idToken = req.headers.authorization?.split("Bearer ")[1];

  if (!idToken) {
    return res.status(401).json({ error: "Unauthorized: No token provided" });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.userId = decodedToken.uid; // Store user ID in request object
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid authentication token" });
  }
}

app.get("/server/get_user_info", authenticate, async (req, res) => {
    try {
        const userId = req.userId;
        const userDoc = await admin.firestore().collection("users").doc(userId).get();

        if (!userDoc.exists) {
            return res.status(404).json({ error: "User not found" });
        }

        const userData = userDoc.data();
        const isBankConnected = userData.access_token ? true : false;

        res.json({
            userId: userId,
            userStatus: isBankConnected ? "connected" : "disconnected"
        });
    } catch (error) {
        res.status(500).json({ error: "Error retrieving user info" });
    }
});



app.post("/server/generate_link_token", authenticate, async (req, res, next) => {
  try {
    const userId = req.userId;

    const createTokenResponse = await plaidClient.linkTokenCreate({
      user: {
        client_user_id: userId,
        phone_number: "+14155550123"
      },
      client_name: "iOS Demo",
      country_codes: ["US"],
      language: "en",
      products: ["auth", "transactions"],
      webhook: "https://sample-webhook-uri.com",
    });

    res.json({
      expiration: createTokenResponse.data.expiration,
      linkToken: createTokenResponse.data.link_token,
    });
  } catch (error) {
    console.error("Error generating Plaid link token:", error);
    next(error);
  }
});

// 🔹 Swap Public Token for Access Token (Unique Per User)
app.post("/server/swap_public_token", authenticate, async (req, res, next) => {
  try {
    const userId = req.userId;

    const result = await plaidClient.itemPublicTokenExchange({
      public_token: req.body.public_token,
    });

    const accessToken = result.data.access_token;
    const itemId = result.data.item_id;

    // Store Access Token for This Specific User in Firestore
    const userRef = admin.firestore().collection("users").doc(userId);
    await userRef.set(
      {
        access_token: accessToken,
        item_id: itemId,
        user_status: "connected",
      },
      { merge: true }
    );

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

app.get("/server/simple_auth", authenticate, async (req, res, next) => {
    try {
        const userId = req.userId;
        const userDoc = await admin.firestore().collection("users").doc(userId).get();

        if (!userDoc.exists || !userDoc.data().access_token) {
            return res.status(400).json({ error: "User has no linked Plaid account." });
        }

        const accessToken = userDoc.data().access_token;

        // Fetch accounts from Plaid
        const authResponse = await plaidClient.authGet({ access_token: accessToken });

        const institutionName = authResponse.data.item.institution_name || "Unknown Bank";
        const accounts = authResponse.data.accounts;

        // Fetch last 30 days of transactions
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);
        const endDate = new Date();
        const formattedStartDate = startDate.toISOString().split("T")[0];
        const formattedEndDate = endDate.toISOString().split("T")[0];

        const transactionsResponse = await plaidClient.transactionsGet({
            access_token: accessToken,
            start_date: formattedStartDate,
            end_date: formattedEndDate,
            options: { count: 10 }
        });

        const transactionsData = transactionsResponse.data.transactions;

        // Map transactions to accounts and store under `accountTransactions`
        const bankAccounts = accounts.map(account => {
            const accountId = account.account_id;

            // Filter transactions for the specific account
            const filteredTransactions = transactionsData
                .filter(tx => tx.account_id === accountId)
                .map(tx => tx.name); // Only store transaction names

            console.log(`Account ${account.name} Transactions:`, filteredTransactions); // ✅ Debugging output

            return {
                institutionName,
                accountMask: account.mask,
                accountName: account.name,
                accountType: account.subtype,
                accountBalance: account.balances.current,
                accountTransactions: filteredTransactions || [] // ✅ Store transactions correctly
            };
        });

        await admin.firestore().collection("users").doc(userId).set(
          {
            bankAccounts: bankAccounts // ✅ Ensure it is stored properly under "bankAccounts"
          },
          { merge: true }
        );


        res.json({ bankAccounts });
    } catch (error) {
        console.error("Error fetching Plaid transactions:", error);
        next(error);
    }
});




app.use((err, req, res, next) => {
  console.error("Server error:", err);
  res.status(500).json({ error: "Internal Server Error" });
});

