import { Router } from 'express';
import { ProductionController } from '../controllers/production.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { authorizeRoles } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import {
  cuttingEntrySchema,
  printingEntrySchema,
  stitchingEntrySchema,
  packingEntrySchema,
} from '../validators/production.validator';

const router = Router();
const controller = new ProductionController();

router.use(authenticateToken);

router.post('/cutting', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(cuttingEntrySchema), controller.cutting);
router.post('/printing', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(printingEntrySchema), controller.printing);
router.post('/stitching', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(stitchingEntrySchema), controller.stitching);
router.post('/packing', authorizeRoles('ADMIN', 'UNIT_SUPERVISOR'), validateRequest(packingEntrySchema), controller.packing);
router.get('/activities', controller.activities);

export default router;
