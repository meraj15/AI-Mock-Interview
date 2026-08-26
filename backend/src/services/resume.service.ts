// pdf-parse uses CJS default export — must import this way for TypeScript compatibility
// eslint-disable-next-line @typescript-eslint/no-require-imports
const pdfParse = require('pdf-parse') as (
  buffer: Buffer
) => Promise<{
  text: string;
  numpages: number;
}>;

import { GoogleGenAI, Type } from '@google/genai';
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

  education: Array<{
    degree: string;
    institution: string;
    year?: string;
  }>;

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

// ── Gemini prompt ─────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `
You are a professional resume parser.

Extract structured information from the provided resume text.

Return ONLY valid JSON matching the provided schema.

IMPORTANT RULES:

1. Never return markdown.
2. Never return explanations.
3. Never return code fences.
4. Never invent information that is not present in the resume.
5. Use empty strings when a text field cannot be determined.
6. Use 0 for experience_years when experience cannot be determined.
7. Use empty arrays when a section has no information.
8. Never return null.
9. Infer target_role from the candidate's actual experience and skills.
10. Keep responsibilities and technologies relevant to the actual resume.
11. Do not duplicate skills.
12. Preserve important technical terminology.
`;

// ── Service ───────────────────────────────────────────────────────────────────

export class ResumeService {
  private client: GoogleGenAI | null = null;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;

    if (apiKey && apiKey.trim().length > 0) {
      this.client = new GoogleGenAI({
        apiKey: apiKey.trim(),
      });

      logger.info(
        'Gemini resume service initialised'
      );
    } else {
      logger.warn(
        'GEMINI_API_KEY not set — resume parsing will use fallback extraction'
      );
    }
  }

  /**
   * Parse a PDF/TXT buffer:
   *
   * File
   *   ↓
   * Extract text
   *   ↓
   * Gemini
   *   ↓
   * Structured ResumeProfile
   */
  async parseResume(
    fileBuffer: Buffer,
    fileName: string
  ): Promise<ResumeProfile> {
    const rawText = await this.extractText(fileBuffer);

    if (!rawText || rawText.trim().length < 30) {
      throw new Error(
        'Could not extract readable text from this file. ' +
          'Make sure it is a text-based PDF (not a scanned image).'
      );
    }

    logger.info(
      `Extracted ${rawText.length} characters from ${fileName}`
    );

    return this.structureWithAI(
      rawText,
      fileName
    );
  }

  // ── Step 1: PDF text extraction ────────────────────────────────────────────

  private async extractText(
    buffer: Buffer
  ): Promise<string> {
    try {
      const data = await pdfParse(buffer);

      return data.text ?? '';
    } catch (err) {
      logger.error(
        'PDF parse error:',
        err
      );

      // Fallback for plain text files
      return buffer.toString('utf-8');
    }
  }

  // ── Step 2: AI structuring ─────────────────────────────────────────────────

  private async structureWithAI(
    resumeText: string,
    fileName: string
  ): Promise<ResumeProfile> {
    if (this.client) {
      return this.structureWithGemini(
        resumeText
      );
    }

    return this.basicFallbackExtraction(
      resumeText,
      fileName
    );
  }

  // ── Step 3: Gemini structuring ─────────────────────────────────────────────

  private async structureWithGemini(
    resumeText: string
  ): Promise<ResumeProfile> {
    // Prevent unnecessarily large prompts.
    const truncated =
      resumeText.length > 12000
        ? resumeText.slice(0, 12000)
        : resumeText;

    try {
      const response =
        await this.client!.models.generateContent({
          model: 'gemini-3.7-flash',

          contents: `
${SYSTEM_PROMPT}

RESUME TEXT:

${truncated}
`,

          config: {
            temperature: 0.1,

            maxOutputTokens: 4096,

            responseMimeType:
              'application/json',

            responseSchema: {
              type: Type.OBJECT,

              properties: {
                name: {
                  type: Type.STRING,
                },

                email: {
                  type: Type.STRING,
                },

                phone: {
                  type: Type.STRING,
                },

                target_role: {
                  type: Type.STRING,
                },

                experience_years: {
                  type: Type.NUMBER,
                },

                summary: {
                  type: Type.STRING,
                },

                skills: {
                  type: Type.ARRAY,

                  items: {
                    type: Type.STRING,
                  },
                },

                education: {
                  type: Type.ARRAY,

                  items: {
                    type: Type.OBJECT,

                    properties: {
                      degree: {
                        type: Type.STRING,
                      },

                      institution: {
                        type: Type.STRING,
                      },

                      year: {
                        type: Type.STRING,
                      },
                    },

                    required: [
                      'degree',
                      'institution',
                      'year',
                    ],

                    additionalProperties: false,
                  },
                },

                work_experience: {
                  type: Type.ARRAY,

                  items: {
                    type: Type.OBJECT,

                    properties: {
                      company: {
                        type: Type.STRING,
                      },

                      role: {
                        type: Type.STRING,
                      },

                      duration: {
                        type: Type.STRING,
                      },

                      responsibilities: {
                        type: Type.ARRAY,

                        items: {
                          type: Type.STRING,
                        },
                      },

                      technologies: {
                        type: Type.ARRAY,

                        items: {
                          type: Type.STRING,
                        },
                      },
                    },

                    required: [
                      'company',
                      'role',
                      'duration',
                      'responsibilities',
                      'technologies',
                    ],

                    additionalProperties: false,
                  },
                },

                projects: {
                  type: Type.ARRAY,

                  items: {
                    type: Type.OBJECT,

                    properties: {
                      name: {
                        type: Type.STRING,
                      },

                      description: {
                        type: Type.STRING,
                      },

                      technologies: {
                        type: Type.ARRAY,

                        items: {
                          type: Type.STRING,
                        },
                      },
                    },

                    required: [
                      'name',
                      'description',
                      'technologies',
                    ],

                    additionalProperties: false,
                  },
                },

                certifications: {
                  type: Type.ARRAY,

                  items: {
                    type: Type.OBJECT,

                    properties: {
                      name: {
                        type: Type.STRING,
                      },

                      issuer: {
                        type: Type.STRING,
                      },

                      year: {
                        type: Type.STRING,
                      },
                    },

                    required: [
                      'name',
                      'issuer',
                      'year',
                    ],

                    additionalProperties: false,
                  },
                },
              },

              required: [
                'name',
                'email',
                'phone',
                'target_role',
                'experience_years',
                'summary',
                'skills',
                'education',
                'work_experience',
                'projects',
                'certifications',
              ],

              additionalProperties: false,
            },
          },
        });

      // ── Get Gemini response ────────────────────────────────────────────────

      const raw =
        response.text?.trim() ?? '';

      if (!raw) {
        logger.error(
          'Gemini returned an empty resume response'
        );

        throw new Error(
          'AI returned an empty response. Please try again.'
        );
      }

      // ── Parse JSON ─────────────────────────────────────────────────────────

      let parsed: unknown;

      try {
        parsed = JSON.parse(raw);
      } catch {
        logger.error(
          'Failed to parse Gemini JSON response:',
          raw.slice(0, 500)
        );

        throw new Error(
          'AI returned an invalid response. Please try again.'
        );
      }

      // ── Validate object ────────────────────────────────────────────────────

      if (
        !parsed ||
        typeof parsed !== 'object' ||
        Array.isArray(parsed)
      ) {
        throw new Error(
          'AI returned an invalid resume profile.'
        );
      }

      return this.sanitizeProfile(
        parsed as Partial<ResumeProfile>
      );
    } catch (err) {
      logger.error(
        'Gemini resume parsing failed:',
        err
      );

      throw err;
    }
  }

  // ── Step 4: Regex-based fallback ───────────────────────────────────────────

  /**
   * Fallback extraction when GEMINI_API_KEY is not configured.
   */
  private basicFallbackExtraction(
    text: string,
    fileName: string
  ): ResumeProfile {
    const lines = text
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    // ── Email ────────────────────────────────────────────────────────────────

    const emailMatch = text.match(
      /[\w.+-]+@[\w-]+\.[a-z]{2,}/i
    );

    const email =
      emailMatch?.[0] ?? '';

    // ── Phone ────────────────────────────────────────────────────────────────

    const phoneMatch = text.match(
      /(\+?\d[\d\s\-().]{7,15}\d)/
    );

    const phone =
      phoneMatch?.[0]?.trim() ?? '';

    // ── Name ─────────────────────────────────────────────────────────────────

    const name =
      lines[0] ??
      fileName
        .replace(/\.[^.]+$/, '')
        .replace(/[_-]/g, ' ');

    // ── Skills ───────────────────────────────────────────────────────────────

    const skillKeywords = [
      'flutter',
      'dart',
      'react',
      'node',
      'python',
      'java',
      'kotlin',
      'swift',
      'typescript',
      'javascript',
      'firebase',
      'postgresql',
      'mongodb',
      'docker',
      'aws',
      'git',
      'redis',
      'express',
      'django',
      'fastapi',
      'spring',
      'mysql',
      'sql',
      'rest',
      'graphql',
      'bloc',
      'provider',
      'riverpod',
      'clean architecture',
      'cicd',
      'kubernetes',
      'terraform',
    ];

    const skills: string[] = [];

    const lowerText =
      text.toLowerCase();

    skillKeywords.forEach((keyword) => {
      if (
        lowerText.includes(keyword) &&
        !skills.includes(keyword)
      ) {
        skills.push(
          keyword.charAt(0).toUpperCase() +
            keyword.slice(1)
        );
      }
    });

    // ── Experience ──────────────────────────────────────────────────────────

    const expMatch = text.match(
      /(\d+\.?\d*)\s*(year|yr)/i
    );

    const experience_years =
      expMatch
        ? parseFloat(expMatch[1])
        : 0;

    // ── Target role ──────────────────────────────────────────────────────────

    const roleLine = lines
      .slice(0, 5)
      .join(' ')
      .toLowerCase();

    let target_role =
      'Software Engineer';

    if (roleLine.includes('flutter')) {
      target_role =
        'Flutter Developer';
    } else if (
      roleLine.includes('backend')
    ) {
      target_role =
        'Backend Engineer';
    } else if (
      roleLine.includes('frontend') ||
      roleLine.includes('react')
    ) {
      target_role =
        'Frontend Developer';
    } else if (
      roleLine.includes('fullstack') ||
      roleLine.includes('full stack')
    ) {
      target_role =
        'Full Stack Engineer';
    } else if (
      roleLine.includes('android')
    ) {
      target_role =
        'Android Developer';
    } else if (
      roleLine.includes('ios')
    ) {
      target_role =
        'iOS Developer';
    } else if (
      roleLine.includes('devops')
    ) {
      target_role =
        'DevOps Engineer';
    } else if (
      roleLine.includes('data') ||
      roleLine.includes('ml')
    ) {
      target_role =
        'Data / ML Engineer';
    }

    // ── Summary ──────────────────────────────────────────────────────────────

    const summary =
      `${name} is a ${target_role} with ${
        experience_years > 0
          ? `${experience_years} years`
          : 'early-career'
      } experience. Skills include ${
        skills.slice(0, 5).join(', ')
      }.`;

    // ── Return ───────────────────────────────────────────────────────────────

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

  // ── Sanitize profile ───────────────────────────────────────────────────────

  private sanitizeProfile(
    p: Partial<ResumeProfile>
  ): ResumeProfile {
    return {
      name:
        typeof p.name === 'string'
          ? p.name.trim()
          : '',

      email:
        typeof p.email === 'string'
          ? p.email.trim()
          : '',

      phone:
        typeof p.phone === 'string'
          ? p.phone.trim()
          : '',

      target_role:
        typeof p.target_role === 'string' &&
        p.target_role.trim()
          ? p.target_role.trim()
          : 'Software Engineer',

      experience_years:
        typeof p.experience_years === 'number' &&
        Number.isFinite(
          p.experience_years
        )
          ? p.experience_years
          : 0,

      summary:
        typeof p.summary === 'string'
          ? p.summary.trim()
          : '',

      skills:
        Array.isArray(p.skills)
          ? p.skills.filter(
              (skill): skill is string =>
                typeof skill === 'string' &&
                skill.trim().length > 0
            )
          : [],

      education:
        Array.isArray(p.education)
          ? p.education
          : [],

      work_experience:
        Array.isArray(p.work_experience)
          ? p.work_experience
          : [],

      projects:
        Array.isArray(p.projects)
          ? p.projects
          : [],

      certifications:
        Array.isArray(p.certifications)
          ? p.certifications
          : [],
    };
  }
}

export const resumeService =
  new ResumeService();  