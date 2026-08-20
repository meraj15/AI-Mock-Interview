import { Router } from 'express';
import { profileController } from '../controllers/profile.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// All profile endpoints require authentication
router.use(authMiddleware);

router.get('/', profileController.getProfile);
router.put('/', profileController.updateProfile);

export default router;
