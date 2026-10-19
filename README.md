# CS 4750 Project

React (Vite) frontend + Express API + MySQL on Google Cloud SQL, deployed to App Engine.

```
Browser ──► React (client/)  ──fetch /api/*──►  Express (server/)  ──mysql2──►  Cloud SQL (MySQL)
```

React never talks to the database directly. Every DB operation goes through an Express route in `server/index.js`, which keeps the DB password on the server.

## Repo layout

```
server/
  db.js           MySQL connection pool (local TCP or App Engine socket)
  index.js        API routes + serves the built React app
client/           React app (Vite)
  src/App.jsx
  vite.config.js  proxies /api to Express during dev
sql/schema.sql    table definitions
.env.example      template for local DB credentials
app.yaml.example  template for App Engine config
```

## GCP details

| Thing | Value |
|---|---|
| Project ID | `cs4750-project-512018` |
| Cloud SQL instance | `db` (region `us-east4`) |
| Connection name | `cs4750-project-512018:us-east4:db` |
| Database | `todo-app` |

Ask Lulu for the DB username/password. They are never committed to this repo.

## One-time setup (each team member)

**1. Get project access.** Lulu adds your Google account in the GCP console under *IAM & Admin → IAM → Grant access* with the **Cloud SQL Client** role. Accept the email invite.

**2. Install tools.**
- Node.js 22 LTS: https://nodejs.org (check with `node -v`)
- Google Cloud CLI: https://cloud.google.com/sdk/docs/install
- Cloud SQL Auth Proxy (v2): https://cloud.google.com/sql/docs/mysql/connect-auth-proxy#install. Put the binary somewhere on your PATH or in the repo root (it's not committed).

**3. Log in to gcloud.**
```bash
gcloud auth login
gcloud auth application-default login   # the proxy uses these credentials
gcloud config set project cs4750-project-512018
```

**4. Clone and install.**
```bash
git clone <repo-url>
cd cs4750-project
npm install
npm --prefix client install
```

**5. Create your `.env`.**
```bash
cp .env.example .env
```
Then fill in `DB_USER` and `DB_PASS`.

## Running locally

You need three terminals.

**Terminal 1: database proxy.** This makes the Cloud SQL database look like it's running on your machine at `127.0.0.1:3306`.
```bash
cloud-sql-proxy --port 3306 cs4750-project-512018:us-east4:db
```
If you already run MySQL locally on 3306, use `--port 3307` and set `DB_PORT=3307` in `.env`.

**Terminal 2: API server** (port 8080).
```bash
npm run dev:server
```

**Terminal 3: React dev server** (port 5173, hot reload).
```bash
cd client
npm run dev
```

Open http://localhost:5173. To check the DB connection, open http://localhost:5173/api/health. You should see `{"ok":true,"db":"todo-app",...}`.

Restart Terminal 2 after editing anything in `server/`. React changes reload automatically.

## Adding a feature

1. **Table:** add the `CREATE TABLE` to `sql/schema.sql` and run it on the DB (see "Running SQL" below). Tell the group, since everyone shares one database.
2. **API route** in `server/index.js`:
   ```js
   app.get('/api/todos', async (req, res) => {
     try {
       const [rows] = await pool.query('SELECT * FROM todos WHERE userID = ?', [req.query.userID]);
       res.json(rows);
     } catch (err) {
       console.error(err);
       res.status(500).json({ error: 'Failed to load todos' });
     }
   });
   ```
   **Always use `?` placeholders** for any value coming from the user. Never build SQL with string concatenation or template literals, because that's how SQL injection happens.
3. **React:** call it with `fetch('/api/todos')`. Use relative `/api/...` paths, never `http://localhost:8080`, so the same code works locally and deployed.

All API routes must be defined **above** the static-file/catch-all lines at the bottom of `server/index.js`, or the catch-all will swallow them.

## Running SQL

- **Console:** GCP console → SQL → `db` → **Cloud SQL Studio**, log in with the DB user, select database `todo-app`.
- **CLI** (with the proxy running): `mysql -h 127.0.0.1 -P 3306 -u <user> -p todo-app`

The database name has a hyphen, so in raw SQL write it with backticks: ``USE `todo-app`;``

## Deploying

Only one person should deploy at a time, since every deploy replaces the live app.

1. Copy the config template (first time only) and fill in `DB_PASS`:
   ```bash
   cp app.yaml.example app.yaml
   ```
2. Deploy from the repo root:
   ```bash
   gcloud app deploy
   ```
   App Engine runs `npm install`, then the `gcp-build` script builds the React app, then `npm start` runs Express.
3. Open it: `gcloud app browse`, then check `/api/health` on the live URL.

Logs: `gcloud app logs tail -s default`, or GCP console → Logging → Logs Explorer.

Deploying needs more than Cloud SQL Client. Lulu grants **App Engine Deployer**, **Service Account User**, **Cloud Build Editor**, and **Storage Admin** to whoever deploys (or **Editor** to keep it simple).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `/api/health` → `ECONNREFUSED` | Proxy isn't running, or wrong `DB_PORT`. |
| `ETIMEDOUT` or proxy can't connect | The Cloud SQL instance is stopped. Start it in the console (SQL → `db` → Start). |
| `ER_ACCESS_DENIED_ERROR` | Wrong `DB_USER`/`DB_PASS` in `.env` (or `app.yaml` when deployed). |
| `ER_BAD_DB_ERROR` | `DB_NAME` is wrong. It's `todo-app`. |
| `ER_NO_SUCH_TABLE` | Table hasn't been created. Run `sql/schema.sql`. |
| Proxy says permission denied / 403 | You're missing the Cloud SQL Client role, or forgot `gcloud auth application-default login`. |
| React page loads but `/api` calls 404 in dev | Express (Terminal 2) isn't running. |
| Deployed site works but DB fails | Check `app.yaml` values and the logs. The App Engine service account needs the Cloud SQL Client role. |

## Rules

- Never commit `.env` or `app.yaml`. Both are in `.gitignore`.
- Everyone shares one database. Don't `DROP` or bulk-delete without telling the group.
- Stop the Cloud SQL instance when nobody is working on the project if credits are tight.
