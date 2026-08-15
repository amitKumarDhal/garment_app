import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import clientRoutes from './client.routes';
import productRoutes from './product.routes';
import quotationRoutes from './quotation.routes';
import orderRoutes from './order.routes';
import paymentRoutes from './payment.routes';
import inventoryRoutes from './inventory.routes';
import productionRoutes from './production.routes';
import notificationRoutes from './notification.routes';
import analyticsRoutes from './analytics.routes';
import mediaRoutes from './media.routes';

const router = Router();

// API Healthcheck endpoint
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'Zobra Production ERP API',
    version: 'v1.0.0',
    timestamp: new Date().toISOString(),
  });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/clients', clientRoutes);
router.use('/products', productRoutes);
router.use('/quotations', quotationRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/inventory', inventoryRoutes);
router.use('/production', productionRoutes);
router.use('/notifications', notificationRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/media', mediaRoutes);

export default router;
