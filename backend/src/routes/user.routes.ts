import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { userApprovalSchema } from '../validators/auth.validator';

const router = Router();
const controller = new UserController();

router.use(authenticateToken);

router.get('/pending', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), controller.getPending);
router.post('/:id/approve', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(userApprovalSchema), controller.approve);
router.post('/:id/reject', authorizeRoles('ADMIN'), controller.remove);
router.delete('/:id', authorizeRoles('ADMIN'), controller.remove);

export default router;
