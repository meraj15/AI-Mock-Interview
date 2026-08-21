import { Router } from 'express';
import multer from 'multer';
import { resumeController } from '../controllers/resume.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Store file in memory — we only need the buffer to extract text, no disk storage needed
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (_req, file, cb) => {
    const allowed = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ];
    // Also allow by extension as some mobile clients send generic MIME types
    const ext = file.originalname.split('.').pop()?.toLowerCase();
    const allowedExts = ['pdf', 'doc', 'docx', 'txt'];

    if (allowed.includes(file.mimetype) || (ext && allowedExts.includes(ext))) {
      cb(null, true);
    } else {
      cb(new Error(`Unsupported file type: ${file.mimetype}. Use PDF, DOC, DOCX, or TXT.`));
    }
  },
});

// POST /api/resume/parse  (protected — requires valid JWT)
router.post(
  '/parse',
  authMiddleware,
  upload.single('file'),
  resumeController.parseResume
);

export default router;
