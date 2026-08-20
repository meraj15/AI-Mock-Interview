import { Router } from 'express';
import { resumeController } from '../controllers/resume.controller';

const router = Router();

// Endpoint to parse uploaded PDF/DOC resume
router.post('/parse', (req, res, next) => resumeController.parseFile(req, res, next));

// Endpoint to parse raw pasted resume text
router.post('/parse-text', (req, res, next) => resumeController.parseText(req, res, next));

export default router;
