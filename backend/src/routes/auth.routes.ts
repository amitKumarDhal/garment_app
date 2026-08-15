import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authRateLimiter } from '../middleware/rateLimit.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { registerSchema, loginSchema } from '../validators/auth.validator';

const router = Router();
const controller = new AuthController();

router.post('/register', authRateLimiter, validateRequest(registerSchema), controller.register);
router.post('/login', authRateLimiter, validateRequest(loginSchema), controller.login);
router.get('/me', authenticateToken, controller.getMe);

export default router;
