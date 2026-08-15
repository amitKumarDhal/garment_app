import { Router } from 'express';
import { OrderController } from '../controllers/order.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { createOrderSchema, approveOrderSchema } from '../validators/order.validator';

const router = Router();
const controller = new OrderController();

router.use(authenticateToken);

router.get('/', controller.getAll);
router.get('/:id', controller.getById);
router.post('/', validateRequest(createOrderSchema), controller.create);
router.post('/:id/approve', authorizeRoles('ADMIN', 'SALES_MANAGER'), validateRequest(approveOrderSchema), controller.approve);
router.post('/:id/reject', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.reject);
router.post('/:id/request-delete', controller.requestDelete);

export default router;
