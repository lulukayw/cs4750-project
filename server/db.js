import mysql from 'mysql2/promise';
import { Connector } from '@google-cloud/cloud-sql-connector';

const connector = new Connector();

const getPoolConfig = async () => {
  if (process.env.INSTANCE_CONNECTION_NAME) {
    const clientOpts = await connector.getOptions({
      instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,
      ipType: process.env.DB_IP_TYPE || 'PUBLIC',
    });

    return {
      ...clientOpts,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 5,
    };
  }
};

const poolConfig = await getPoolConfig();
const pool = mysql.createPool(poolConfig);

export default pool;