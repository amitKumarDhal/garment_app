import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { envConfig } from './config/env.config';
import routes from './routes';
import { errorHandler } from './middleware/error.middleware';
import { apiRateLimiter } from './middleware/rateLimit.middleware';

const app: Application = express();
// Trust Hostinger's reverse proxy
app.set('trust proxy', 1);

// Security Middleware
app.use(helmet());
app.use(cors({ origin: envConfig.corsOrigin, credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

if (envConfig.nodeEnv !== 'test') {
  app.use(morgan('dev'));
}

// Global Rate Limiting
app.use('/api/', apiRateLimiter);

// Root & Healthcheck endpoints
app.get(['/', '/api/health'], (_req, res) => {
  res.status(200).json({ status: 'healthy', service: 'Zobra Production ERP API' });
});

// Mount API v1 Routes
app.use('/api/v1', routes);

// Global Error Handler
app.use(errorHandler);

export default app;
