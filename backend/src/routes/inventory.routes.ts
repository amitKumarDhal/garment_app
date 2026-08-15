import { Router } from 'express';
import { InventoryController } from '../controllers/inventory.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { inventoryTransactionSchema } from '../validators/inventory.validator';

const router = Router();
const controller = new InventoryController();

router.use(authenticateToken);

router.get('/', controller.getItems);
router.get('/transactions', controller.getTransactions);
router.post('/transactions', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(inventoryTransactionSchema), controller.recordTransaction);

export default router;
