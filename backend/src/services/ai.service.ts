import { GoogleGenerativeAI } from '@google/generative-ai';
import { config } from '../config';

export interface GeneratedQuestion {
  primaryQuestion: string;
  followUpQuestion: string;
  category: string;
  contextHint: string;
}

export class AIService {
  private gemini: GoogleGenerativeAI | null = null;

  private getClient(): GoogleGenerativeAI {
    if (!this.gemini) {
      if (!config.gemini.apiKey) {
        throw new Error('GEMINI_API_KEY is not configured');
      }

      this.gemini = new GoogleGenerativeAI(config.gemini.apiKey);
    }

    return this.gemini;
  }

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

    // -----------------------------
    // Validate input
    // -----------------------------

    if (!role?.trim()) {
      throw new Error('Role is required');
    }

    if (!questionCount || questionCount < 1) {
      throw new Error('Question count must be greater than 0');
    }

    if (questionCount > 50) {
      throw new Error('Question count cannot exceed 50');
    }

    // -----------------------------
    // Difficulty
    // -----------------------------

    const difficultyGuide: Record<string, string> = {
      easy:
        'fundamental and conceptual questions suitable for juniors or freshers',

      medium:
        'intermediate questions involving practical implementation, debugging, and trade-off reasoning',

      hard:
        'advanced questions involving architecture, edge cases, optimization, scalability, and deep technical reasoning',

      adaptive:
        'start with moderate questions and progressively increase difficulty based on the candidate experience level',
    };

    const difficultyKey = difficulty?.toLowerCase() || 'medium';

    const diffDesc =
      difficultyGuide[difficultyKey] ?? difficultyGuide.medium;

    // -----------------------------
    // Skills
    // -----------------------------

    const skillList =
      skills.length > 0
        ? skills.join(', ')
        : role;

    const expNote = experience
      ? `The candidate has ${experience} of professional experience.`
      : 'The candidate experience level is not specified.';

    // -----------------------------
    // Prompt
    // -----------------------------

    const prompt = `
You are a professional technical interviewer conducting a realistic job interview.

Candidate Role:
${role}

${expNote}

Candidate Skills:
${skillList}

Difficulty:
${diffDesc}

Generate exactly ${questionCount} interview questions.

QUESTION GENERATION RULES:

1. Every question must be directly relevant to the candidate's role.

2. Questions must be based on one or more of the candidate's listed skills.

3. Cover different skills instead of repeatedly testing the same skill.

4. Avoid duplicate or very similar questions.

5. Mix different question styles:
   - Conceptual
   - Practical
   - Scenario-based
   - Problem-solving
   - Debugging
   - Best practices
   - Performance
   - System design when appropriate

6. Questions should sound like questions asked by a real professional interviewer.

7. Prefer practical and real-world questions over simple definition questions.

8. When appropriate, ask about how the candidate would solve a problem in a real project.

9. Match every question to the requested difficulty.

10. Do not ask questions that require skills not included in the candidate's profile unless they are fundamental to the requested role.

11. Do not repeat the same category for every question.

12. Use these categories where appropriate:
   - Core Skills
   - Problem Solving
   - Debugging
   - Best Practices
   - Performance
   - System Design

FOLLOW-UP RULE:

The candidate has NOT answered the primary question yet.

Therefore, "followUpQuestion" must be a POSSIBLE deeper follow-up question related to the primary question.

Do NOT assume what the candidate will answer.

The follow-up should allow the interviewer to explore the same topic more deeply after the candidate responds.

CONTEXT HINT:

"contextHint" should be a short one-sentence explanation of what the interviewer is evaluating with the question.

QUALITY RULES:

- Do not generate generic filler questions.
- Do not generate questions unrelated to the role.
- Do not repeat questions.
- Do not use overly long questions.
- Questions should be natural when spoken by an interviewer.
- Each question should test a meaningful skill.
- Make the interview progressively useful rather than simply listing definitions.

OUTPUT FORMAT:

Return ONLY a valid JSON array.

Do NOT include:
- Markdown
- Code fences
- Explanations
- Comments
- Additional text

Return exactly ${questionCount} objects using this structure:

[
  {
    "primaryQuestion": "...",
    "followUpQuestion": "...",
    "category": "...",
    "contextHint": "..."
  }
]
`;

    // -----------------------------
    // Gemini
    // -----------------------------

    const client = this.getClient();

    const model = client.getGenerativeModel({
      model: 'gemini-1.5-flash',
    });

    const result = await model.generateContent(prompt);

    const text = result.response.text().trim();

    if (!text) {
      throw new Error('Gemini returned an empty response');
    }

    // -----------------------------
    // Clean JSON response
    // -----------------------------

    const clean = text
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/```\s*$/i, '')
      .trim();

    // -----------------------------
    // Parse JSON
    // -----------------------------

    let parsed: unknown;

    try {
      parsed = JSON.parse(clean);
    } catch {
      throw new Error(
        `Gemini returned invalid JSON: ${clean.slice(0, 500)}`,
      );
    }

    // -----------------------------
    // Validate array
    // -----------------------------

    if (!Array.isArray(parsed)) {
      throw new Error('Gemini response is not an array');
    }

    // -----------------------------
    // Validate question count
    // -----------------------------

    if (parsed.length !== questionCount) {
      throw new Error(
        `Gemini returned ${parsed.length} questions, expected ${questionCount}`,
      );
    }

    // -----------------------------
    // Validate question objects
    // -----------------------------

    const validQuestions = parsed.filter((question): question is GeneratedQuestion => {
      if (!question || typeof question !== 'object') {
        return false;
      }

      const q = question as Record<string, unknown>;

      return (
        typeof q.primaryQuestion === 'string' &&
        q.primaryQuestion.trim().length > 0 &&

        typeof q.followUpQuestion === 'string' &&
        q.followUpQuestion.trim().length > 0 &&

        typeof q.category === 'string' &&
        q.category.trim().length > 0 &&

        typeof q.contextHint === 'string' &&
        q.contextHint.trim().length > 0
      );
    });

    // -----------------------------
    // Final validation
    // -----------------------------

    if (validQuestions.length !== questionCount) {
      throw new Error(
        `Gemini returned ${validQuestions.length} valid questions, expected ${questionCount}`,
      );
    }

    return validQuestions.map((question) => ({
      primaryQuestion: question.primaryQuestion.trim(),
      followUpQuestion: question.followUpQuestion.trim(),
      category: question.category.trim(),
      contextHint: question.contextHint.trim(),
    }));
  }
}

export const aiService = new AIService();