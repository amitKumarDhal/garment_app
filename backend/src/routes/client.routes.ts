import { Router } from 'express';
import { ClientController } from '../controllers/client.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();
const controller = new ClientController();

router.use(authenticateToken);

router.get('/', controller.getAll);
router.post('/', controller.create);

export default router;
