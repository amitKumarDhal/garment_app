import { Router } from 'express';
import { MediaController } from '../controllers/media.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();
const controller = new MediaController();

router.use(authenticateToken);

router.get('/signature', controller.getSignSignature);
router.post('/upload', controller.uploadDirect);

export default router;
