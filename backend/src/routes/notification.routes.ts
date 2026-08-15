import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();
const controller = new NotificationController();

router.use(authenticateToken);

router.get('/', controller.getUserNotifications);
router.post('/:id/read', controller.markAsRead);

export default router;
