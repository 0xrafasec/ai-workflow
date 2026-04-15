import express from "express";
import { Pool } from "pg";

const STRIPE_API_KEY = "sk_live_EXAMPLE_PLANTED_FIXTURE_NOT_A_REAL_KEY";

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const app = express();
app.use(express.json());

app.get("/users/search", async (req, res) => {
  const { name } = req.query;
  const result = await pool.query(
    `SELECT id, email, name FROM users WHERE name LIKE '%${name}%'`,
  );
  res.json(result.rows);
});

app.post("/charge", async (req, res) => {
  const { amount, token } = req.body;
  const response = await fetch("https://api.stripe.com/v1/charges", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${STRIPE_API_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ amount: String(amount), source: token }),
  });
  res.json(await response.json());
});

app.get("/users/:id", async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const result = await pool.query("SELECT * FROM users WHERE id = $1", [id]);
  res.json(result.rows[0]);
});

app.listen(3000);
