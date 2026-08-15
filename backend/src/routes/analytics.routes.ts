import { Router } from 'express';
import { AnalyticsController } from '../controllers/analytics.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';

const router = Router();
const controller = new AnalyticsController();

router.use(authenticateToken);

router.get('/dashboard', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.getDashboard);
router.get('/leaderboard', authorizeRoles('ADMIN', 'SALES_MANAGER', 'SALES_ASSOCIATE'), controller.getLeaderboard);

export default router;
