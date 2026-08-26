import { GoogleGenAI, Type } from '@google/genai';
import { config } from '../config';

export interface GeneratedQuestion {
  primaryQuestion: string;
  followUpQuestion: string;
  category: string;
  contextHint: string;
}

const FALLBACK_MODELS = [
  'gemini-3.5-flash-lite',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
];

const ALLOWED_CATEGORIES = [
  'Core Skills',
  'Problem Solving',
  'System Design',
  'Best Practices',
  'Debugging',
  'Performance',
] as const;

export class AIService {
  private client: GoogleGenAI | null = null;

  /**
   * Create or return the singleton Gemini client instance.
   */
  private getClient(): GoogleGenAI {
    if (!this.client) {
      if (!config.gemini.apiKey?.trim()) {
        throw new Error(
          'GEMINI_API_KEY is not set in environment variables',
        );
      }

      this.client = new GoogleGenAI({
        apiKey: config.gemini.apiKey.trim(),
      });
    }

    return this.client;
  }

  /**
   * Determine if an error is temporary (503, 429, high demand, overloaded, etc.)
   */
  private isTemporaryError(err: unknown): boolean {
    if (!err) return false;

    const errorObj = err as Record<string, any>;
    const status =
      errorObj?.status ||
      errorObj?.statusCode ||
      errorObj?.code ||
      errorObj?.error?.code ||
      errorObj?.error?.status;

    if (
      status === 503 ||
      status === 429 ||
      status === 'UNAVAILABLE' ||
      status === 'RESOURCE_EXHAUSTED'
    ) {
      return true;
    }

    const errorStr = (
      typeof err === 'string'
        ? err
        : errorObj?.message || JSON.stringify(err)
    ).toLowerCase();

    const temporaryKeywords = [
      '503',
      '429',
      'unavailable',
      'high demand',
      'overloaded',
      'rate limit',
      'resource exhausted',
      'temporarily unavailable',
    ];

    return temporaryKeywords.some((keyword) => errorStr.includes(keyword));
  }

  /**
   * Generate technical interview questions with model fallback on temporary errors.
   */
  async generateInterviewQuestions(params: {
    role: string;
    skills: string[];
    difficulty: string;
    questionCount: number;
    experience?: string;
  }): Promise<GeneratedQuestion[]> {
    const {
      role,
      skills,
      difficulty,
      questionCount,
      experience,
    } = params;

    // -----------------------------------------
    // Validate role
    // -----------------------------------------
    if (!role || typeof role !== 'string' || !role.trim()) {
      throw new Error('Role is required');
    }

    // -----------------------------------------
    // Validate question count
    // -----------------------------------------
    if (
      typeof questionCount !== 'number' ||
      !Number.isInteger(questionCount) ||
      questionCount < 1 ||
      questionCount > 50
    ) {
      throw new Error('Question count must be an integer between 1 and 50');
    }

    // -----------------------------------------
    // Difficulty guide
    // -----------------------------------------
    const difficultyGuide: Record<string, string> = {
      easy: 'fundamental and conceptual questions suitable for juniors or freshers',
      medium: 'intermediate questions involving practical implementation, debugging, and trade-off reasoning',
      hard: 'advanced or senior-level questions involving architecture, edge cases, optimization, scalability, system design, and deep technical reasoning',
      adaptive: 'mixed difficulty that progressively tests deeper concepts based on the candidate profile',
    };

    const difficultyKey =
      difficulty?.trim().toLowerCase() || 'medium';

    const diffDesc =
      difficultyGuide[difficultyKey] ?? difficultyGuide.medium;

    // -----------------------------------------
    // Clean skills safely
    // -----------------------------------------
    const cleanedSkills = Array.isArray(skills)
      ? skills
          .filter((skill) => typeof skill === 'string' && skill.trim().length > 0)
          .map((skill) => skill.trim())
      : [];

    const skillList =
      cleanedSkills.length > 0 ? cleanedSkills.join(', ') : role.trim();

    // -----------------------------------------
    // Experience note
    // -----------------------------------------
    const expNote = experience?.trim()
      ? `The candidate has ${experience.trim()} of professional experience.`
      : 'The candidate experience level is not specified.';

    // -----------------------------------------
    // Construct Prompt
    // -----------------------------------------
    const prompt = `
You are an expert technical interviewer conducting a realistic professional job interview.

Candidate Role:
${role.trim()}

Candidate Experience:
${expNote}

Candidate Skills:
${skillList}

Difficulty:
${diffDesc}

Generate exactly ${questionCount} interview questions.

QUESTION GENERATION RULES:
1. Every question must be directly relevant to the candidate's role.
2. Every question must test at least one of the candidate's listed skills.
3. Cover different skills across the questions without duplicates.
4. Mix conceptual, practical, scenario-based, problem-solving, debugging, best practices, performance, and system design questions where appropriate.
5. Prefer realistic, practical engineering questions over trivial memorization questions.
6. Questions should sound natural and professional when spoken by an interviewer.
7. Match every question strictly to the requested difficulty level.
8. Use only these allowed categories:
   - Core Skills
   - Problem Solving
   - System Design
   - Best Practices
   - Debugging
   - Performance

FOLLOW-UP QUESTION RULE:
The candidate has NOT answered the primary question yet.
Therefore, followUpQuestion must be a possible deeper follow-up question that an interviewer could ask AFTER the candidate answers the primary question.
Do NOT assume the candidate's answer. The follow-up must explore deeper trade-offs, edge cases, internals, or alternatives related to the same topic.

CONTEXT HINT RULE:
contextHint must be a short, single-sentence explanation of what specific competency or concept the interviewer is evaluating.

Return a JSON array containing exactly ${questionCount} question objects.
`;

    console.log('[AIService] Generating questions with params:', {
      role: role.trim(),
      skills: cleanedSkills,
      difficulty: difficultyKey,
      questionCount,
      experience: experience?.trim() || undefined,
    });

    const client = this.getClient();

    let response: any = null;
    let lastError: any = null;

    // -----------------------------------------
    // Fallback Loop over models
    // -----------------------------------------
    for (let i = 0; i < FALLBACK_MODELS.length; i++) {
      const model = FALLBACK_MODELS[i];
      const hasNext = i < FALLBACK_MODELS.length - 1;

      console.log(`[AIService] Calling Gemini model "${model}"...`);

      try {
        response = await client.models.generateContent({
          model,
          contents: prompt,
          config: {
            responseMimeType: 'application/json',
            responseSchema: {
              type: Type.ARRAY,
              minItems: questionCount,
              maxItems: questionCount,
              items: {
                type: Type.OBJECT,
                properties: {
                  primaryQuestion: {
                    type: Type.STRING,
                    description: 'The main technical interview question.',
                  },
                  followUpQuestion: {
                    type: Type.STRING,
                    description:
                      'A possible deeper follow-up question related to the primary question that could be asked after the candidate answers.',
                  },
                  category: {
                    type: Type.STRING,
                    enum: [...ALLOWED_CATEGORIES],
                    description: 'The category of the interview question.',
                  },
                  contextHint: {
                    type: Type.STRING,
                    description:
                      'A short one-sentence explanation of what the interviewer is evaluating.',
                  },
                },
                required: [
                  'primaryQuestion',
                  'followUpQuestion',
                  'category',
                  'contextHint',
                ],
                additionalProperties: false,
              },
            },
          },
        });

        console.log(`[AIService] Gemini model "${model}" succeeded`);
        lastError = null;
        break;
      } catch (err: any) {
        console.error(`[AIService] Gemini model "${model}" failed`);
        lastError = err;

        if (this.isTemporaryError(err) && hasNext) {
          console.log('[AIService] Trying next Gemini model...');
          continue;
        }

        // If not a temporary error or no fallback models left, throw
        throw new Error(`Gemini API Error: ${err?.message || JSON.stringify(err)}`);
      }
    }

    if (!response) {
      throw new Error(
        `All Gemini models failed. Last error: ${lastError?.message || JSON.stringify(lastError)}`,
      );
    }

    // -----------------------------------------
    // Parse Gemini response
    // -----------------------------------------
    const text = response.text?.trim();
    if (!text) {
      console.error('[AIService] Gemini returned an empty response');
      throw new Error('Gemini returned an empty response');
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      console.error('[AIService] Failed to parse JSON from Gemini:', text);
      throw new Error(`Gemini returned invalid JSON: ${text.slice(0, 500)}`);
    }

    if (!Array.isArray(parsed)) {
      console.error('[AIService] Response is not an array:', parsed);
      throw new Error('Gemini response is not a questions array');
    }

    // -----------------------------------------
    // Validate exact question count
    // -----------------------------------------
    if (parsed.length !== questionCount) {
      console.error(
        `[AIService] Question count mismatch. Got ${parsed.length}, expected ${questionCount}`,
      );
      throw new Error(
        `Gemini returned ${parsed.length} questions, expected ${questionCount}`,
      );
    }

    // -----------------------------------------
    // Validate each question
    // -----------------------------------------
    const validQuestions: GeneratedQuestion[] = [];

    for (let index = 0; index < parsed.length; index++) {
      const item = parsed[index];

      if (!item || typeof item !== 'object') {
        throw new Error(`Invalid question object at index ${index}`);
      }

      const q = item as Record<string, unknown>;

      if (typeof q.primaryQuestion !== 'string' || !q.primaryQuestion.trim()) {
        throw new Error(`Invalid or empty primaryQuestion at index ${index}`);
      }

      if (typeof q.followUpQuestion !== 'string' || !q.followUpQuestion.trim()) {
        throw new Error(`Invalid or empty followUpQuestion at index ${index}`);
      }

      if (typeof q.category !== 'string' || !q.category.trim()) {
        throw new Error(`Invalid or empty category at index ${index}`);
      }

      if (typeof q.contextHint !== 'string' || !q.contextHint.trim()) {
        throw new Error(`Invalid or empty contextHint at index ${index}`);
      }

      const trimmedCategory = q.category.trim();
      if (!ALLOWED_CATEGORIES.includes(trimmedCategory as any)) {
        throw new Error(
          `Invalid category "${trimmedCategory}" at index ${index}. Allowed categories: ${ALLOWED_CATEGORIES.join(', ')}`,
        );
      }

      validQuestions.push({
        primaryQuestion: q.primaryQuestion.trim(),
        followUpQuestion: q.followUpQuestion.trim(),
        category: trimmedCategory,
        contextHint: q.contextHint.trim(),
      });
    }

    if (validQuestions.length !== questionCount) {
      throw new Error(
        `Gemini returned ${validQuestions.length} valid questions, expected ${questionCount}`,
      );
    }

    console.log(`[AIService] Successfully generated ${validQuestions.length} questions`);

    return validQuestions;
  }
}

export const aiService = new AIService();