import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';

const router = Router();
const controller = new PaymentController();

router.use(authenticateToken);

router.get('/pending', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.getPending);
router.post('/:id/approve', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.approve);
router.post('/:id/reject', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.reject);

export default router;
