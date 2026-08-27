import { Router } from 'express';
import { profileController } from '../controllers/profile.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// All profile endpoints require authentication
router.use(authMiddleware);

router.get('/', profileController.getProfile);
router.put('/', profileController.updateProfile);
// Merge resume-extracted data without overwriting user-provided values
router.post('/merge-resume', profileController.mergeResumeProfile);

export default router;

