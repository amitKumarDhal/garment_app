import { Router } from 'express';
import { ProductController } from '../controllers/product.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';

const router = Router();
const controller = new ProductController();

router.use(authenticateToken);

router.get('/', controller.getAll);
router.post('/', authorizeRoles('ADMIN', 'SALES_MANAGER'), controller.create);

export default router;
