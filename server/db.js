import mysql from 'mysql2/promise';
import { Connector } from '@google-cloud/cloud-sql-connector';

if (!process.env.INSTANCE_CONNECTION_NAME) {
  throw new Error('INSTANCE_CONNECTION_NAME is not set (check .env)');
}

// The connector authenticates with Application Default Credentials, so no proxy is needed
const connector = new Connector();
const clientOpts = await connector.getOptions({
  instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,
  ipType: process.env.DB_IP_TYPE || 'PUBLIC',
});

const pool = mysql.createPool({
  ...clientOpts,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
});

export default pool;
