import app from './app';
import { envConfig } from './config/env.config';
import { logger } from './utils/logger';

const server = app.listen(envConfig.port, () => {
  logger.info(`🚀 Yoobbel Production ERP Backend API running on port ${envConfig.port} [${envConfig.nodeEnv}]`);
  logger.info(`🔗 Base URL: http://localhost:${envConfig.port}/api/v1`);
});

process.on('unhandledRejection', (reason: Error) => {
  logger.error('Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

export default server;
