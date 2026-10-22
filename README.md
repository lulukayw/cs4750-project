# CS 4750 Project

React (Vite) frontend + Express API + MySQL on Google Cloud SQL.

## Setup (one time)

1. Ask Lulu to add your Google account to GCP project `cs4750-project-512018` with the **Cloud SQL Client** role, and to send you the DB username and password.
2. Install [Node.js 22](https://nodejs.org) and the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install).
3. Log in to Google Cloud:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project cs4750-project-512018
   ```
4. Clone the repo and install packages:
   ```bash
   git clone <repo-url>
   cd cs4750-project
   npm install
   npm --prefix client install
   ```
5. Copy `.env.example` to `.env` and fill it in:
   ```
   INSTANCE_CONNECTION_NAME=cs4750-project-512018:us-east4:db
   DB_NAME=todo-app
   DB_USER=<from Lulu>
   DB_PASS=<from Lulu>
   ```

## Running

1. Start the API server (port 8080): `npm run dev:server`
2. In a second terminal, start React (port 5173): `cd client` then `npm run dev`
3. Open http://localhost:5173. It should say it connected to the database and list the tables.

