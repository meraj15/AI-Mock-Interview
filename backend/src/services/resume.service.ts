// pdf-parse uses CJS default export — must import this way for TypeScript compatibility
// eslint-disable-next-line @typescript-eslint/no-require-imports
const pdfParse = require('pdf-parse') as (buffer: Buffer) => Promise<{ text: string; numpages: number }>;
import OpenAI from 'openai';
import { config } from '../config';
import { logger } from '../utils/logger';

// ── Structured profile shape returned to Flutter ──────────────────────────────

export interface ResumeProfile {
  name: string;
  email: string;
  phone: string;
  target_role: string;
  experience_years: number;
  summary: string;
  skills: string[];
  education: Array<{ degree: string; institution: string; year?: string }>;
  work_experience: Array<{
    company: string;
    role: string;
    duration: string;
    responsibilities: string[];
    technologies: string[];
  }>;
  projects: Array<{
    name: string;
    description: string;
    technologies: string[];
  }>;
  certifications: Array<{
    name: string;
    issuer: string;
    year?: string;
  }>;
}

// ── AI prompt ─────────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are a resume parser. Extract structured information from the resume text and return ONLY valid JSON — no markdown, no explanation, no extra text.

The JSON must exactly match this schema:
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "target_role": "string (infer the most relevant role from experience/skills)",
  "experience_years": number (total years, use 0 for fresher),
  "summary": "string (2-3 sentence professional summary)",
  "skills": ["string"],
  "education": [{ "degree": "string", "institution": "string", "year": "string" }],
  "work_experience": [{
    "company": "string",
    "role": "string",
    "duration": "string",
    "responsibilities": ["string"],
    "technologies": ["string"]
  }],
  "projects": [{
    "name": "string",
    "description": "string",
    "technologies": ["string"]
  }],
  "certifications": [{
    "name": "string",
    "issuer": "string",
    "year": "string"
  }]
}

Return empty arrays [] for sections with no data. Never return null.`;

// ── Service ───────────────────────────────────────────────────────────────────

export class ResumeService {
  private openai: OpenAI | null = null;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;
    if (apiKey && apiKey.trim().length > 0) {
      this.openai = new OpenAI({ apiKey });
    } else {
      logger.warn('OPENAI_API_KEY not set — resume parsing will use fallback extraction');
    }
  }

  /**
   * Parse a PDF buffer → extract text → convert to structured profile via AI.
   */
  async parseResume(fileBuffer: Buffer, fileName: string): Promise<ResumeProfile> {
    // 1. Extract raw text from PDF
    const rawText = await this.extractText(fileBuffer);

    if (!rawText || rawText.trim().length < 30) {
      throw new Error(
        'Could not extract readable text from this file. ' +
          'Make sure it is a text-based PDF (not a scanned image).'
      );
    }

    logger.info(`Extracted ${rawText.length} characters from ${fileName}`);

    // 2. Convert text → structured JSON via AI (or basic fallback)
    const profile = await this.structureWithAI(rawText, fileName);

    return profile;
  }

  // ── Step 1: PDF text extraction ──────────────────────────────────────────

  private async extractText(buffer: Buffer): Promise<string> {
    try {
      const data = await pdfParse(buffer);
      return data.text ?? '';
    } catch (err) {
      logger.error('PDF parse error:', err);
      // For non-PDF text files (txt, doc preview), try treating buffer as UTF-8
      return buffer.toString('utf-8');
    }
  }

  // ── Step 2: AI structuring ───────────────────────────────────────────────

  private async structureWithAI(resumeText: string, fileName: string): Promise<ResumeProfile> {
    if (this.openai) {
      return this.structureWithOpenAI(resumeText);
    }
    // Fallback: basic regex extraction when no API key
    return this.basicFallbackExtraction(resumeText, fileName);
  }

  private async structureWithOpenAI(resumeText: string): Promise<ResumeProfile> {
    // Truncate very long resumes to fit context window
    const truncated = resumeText.length > 8000 ? resumeText.slice(0, 8000) : resumeText;

    const completion = await this.openai!.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: `Parse this resume and return structured JSON:\n\n${truncated}`,
        },
      ],
      temperature: 0.1,
      max_tokens: 2048,
      response_format: { type: 'json_object' },
    });

    const content = completion.choices[0]?.message?.content ?? '{}';

    try {
      const parsed = JSON.parse(content) as ResumeProfile;
      return this.sanitizeProfile(parsed);
    } catch {
      logger.error('Failed to parse AI JSON response:', content.slice(0, 200));
      throw new Error('AI returned an invalid response. Please try again.');
    }
  }

  /**
   * Regex-based fallback when no OpenAI key is configured.
   * Extracts the most obvious fields from plain text.
   */
  private basicFallbackExtraction(text: string, fileName: string): ResumeProfile {
    const lines = text.split('\n').map((l) => l.trim()).filter(Boolean);

    // Email
    const emailMatch = text.match(/[\w.+-]+@[\w-]+\.[a-z]{2,}/i);
    const email = emailMatch ? emailMatch[0] : '';

    // Phone
    const phoneMatch = text.match(/(\+?\d[\d\s\-().]{7,15}\d)/);
    const phone = phoneMatch ? phoneMatch[0].trim() : '';

    // Name: often the first non-empty line that looks like a name
    const name = lines[0] ?? fileName.replace(/\.[^.]+$/, '').replace(/[_-]/g, ' ');

    // Skills: lines containing common tech keywords
    const skillKeywords = [
      'flutter','dart','react','node','python','java','kotlin','swift','typescript',
      'javascript','firebase','postgresql','mongodb','docker','aws','git','redis',
      'express','django','fastapi','spring','mysql','sql','rest','graphql','bloc',
      'provider','riverpod','clean architecture','cicd','kubernetes','terraform',
    ];
    const skills: string[] = [];
    skillKeywords.forEach((kw) => {
      if (text.toLowerCase().includes(kw) && !skills.includes(kw)) {
        skills.push(kw.charAt(0).toUpperCase() + kw.slice(1));
      }
    });

    // Experience years: look for patterns like "2 years" or "1.5 years"
    const expMatch = text.match(/(\d+\.?\d*)\s*(year|yr)/i);
    const experience_years = expMatch ? parseFloat(expMatch[1]) : 0;

    // Target role: look for common title keywords in first 5 lines
    const roleLine = lines.slice(0, 5).join(' ').toLowerCase();
    let target_role = 'Software Engineer';
    if (roleLine.includes('flutter')) target_role = 'Flutter Developer';
    else if (roleLine.includes('backend')) target_role = 'Backend Engineer';
    else if (roleLine.includes('frontend') || roleLine.includes('react')) target_role = 'Frontend Developer';
    else if (roleLine.includes('fullstack') || roleLine.includes('full stack')) target_role = 'Full Stack Engineer';
    else if (roleLine.includes('android')) target_role = 'Android Developer';
    else if (roleLine.includes('ios')) target_role = 'iOS Developer';
    else if (roleLine.includes('devops')) target_role = 'DevOps Engineer';
    else if (roleLine.includes('data') || roleLine.includes('ml')) target_role = 'Data / ML Engineer';

    const summary = `${name} is a ${target_role} with ${experience_years > 0 ? experience_years + ' years' : 'early-career'} experience. Skills include ${skills.slice(0, 5).join(', ')}.`;

    return this.sanitizeProfile({
      name,
      email,
      phone,
      target_role,
      experience_years,
      summary,
      skills,
      education: [],
      work_experience: [],
      projects: [],
      certifications: [],
    });
  }

  // ── Sanitize: ensure all required fields are present ────────────────────

  private sanitizeProfile(p: Partial<ResumeProfile>): ResumeProfile {
    return {
      name: p.name ?? '',
      email: p.email ?? '',
      phone: p.phone ?? '',
      target_role: p.target_role ?? 'Software Engineer',
      experience_years: typeof p.experience_years === 'number' ? p.experience_years : 0,
      summary: p.summary ?? '',
      skills: Array.isArray(p.skills) ? p.skills.filter(Boolean) : [],
      education: Array.isArray(p.education) ? p.education : [],
      work_experience: Array.isArray(p.work_experience) ? p.work_experience : [],
      projects: Array.isArray(p.projects) ? p.projects : [],
      certifications: Array.isArray(p.certifications) ? p.certifications : [],
    };
  }
}

export const resumeService = new ResumeService();
