import { Router } from 'express';
import { QuotationController } from '../controllers/quotation.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { createQuotationSchema } from '../validators/quotation.validator';

const router = Router();
const controller = new QuotationController();

router.use(authenticateToken);

router.get('/', controller.getAll);
router.post('/', validateRequest(createQuotationSchema), controller.create);

export default router;
