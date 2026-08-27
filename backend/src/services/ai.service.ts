import { GoogleGenAI, Type } from '@google/genai';
import { config } from '../config';

export interface InterviewTopic {
  name: string;
  objective: string;
}

export interface InterviewBlueprint {
  topics: InterviewTopic[];
  firstQuestion: string;
}

export interface ConversationalTurn {
  acknowledgement: string;
  action: 'follow_up' | 'new_topic';
  nextQuestion: string;
  nextTopic: string;
  conversationSummary: string;
}

export interface QuestionReview {
  question: string;
  answer: string;
  feedback: string;
  score: number;
}

export interface FinalInterviewEvaluation {
  overallScore: number;
  performanceLevel: 'Excellent' | 'Good' | 'Average' | 'Needs Improvement';
  summary: string;
  strengths: string[];
  areasToImprove: string[];
  skillPerformance: Record<string, number>;
  recommendations: string[];
  questionReviews: QuestionReview[];
}

export interface TranscriptEntry {
  question: string;
  answer: string;
  topic: string;
  type: 'primary' | 'follow_up';
  timestamp?: string;
}

const FALLBACK_MODELS = [
  'gemini-3.5-flash-lite',
  'gemini-3.7-flash',
  'gemini-3.6-flash',
];

export class AIService {
  private client: GoogleGenAI | null = null;

  /**
   * Create or return the singleton Gemini client instance.
   */
  private getClient(): GoogleGenAI {
    if (!this.client) {
      if (!config.gemini.apiKey?.trim()) {
        throw new Error('GEMINI_API_KEY is not set in environment variables');
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
   * Helper to execute Gemini generateContent with fallback models
   */
  private async executeWithFallback(prompt: string, schema: any): Promise<any> {
    const client = this.getClient();
    let response: any = null;
    let lastError: any = null;

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
            responseSchema: schema,
          },
        });

        console.log(`[AIService] Gemini model "${model}" succeeded`);
        lastError = null;
        break;
      } catch (err: any) {
        console.error(`[AIService] Gemini model "${model}" failed:`, err?.message || err);
        lastError = err;

        if (this.isTemporaryError(err) && hasNext) {
          console.log('[AIService] Trying next Gemini model...');
          continue;
        }

        throw new Error(`Gemini API Error: ${err?.message || JSON.stringify(err)}`);
      }
    }

    if (!response) {
      throw new Error(
        `All Gemini models failed. Last error: ${lastError?.message || JSON.stringify(lastError)}`,
      );
    }

    const text = response.text?.trim();
    if (!text) {
      throw new Error('Gemini returned an empty response');
    }

    try {
      return JSON.parse(text);
    } catch {
      throw new Error(`Gemini returned invalid JSON: ${text.slice(0, 500)}`);
    }
  }

  /**
   * STAGE 1: Generate a tailored interview blueprint based on role, experience, skills, and difficulty.
   * Topics are dynamically decided by Gemini to fit candidate profile.
   */
  async generateInterviewPlan(params: {
    role: string;
    experience?: string;
    skills?: string[];
    difficulty?: string;
    questionCount?: number;
  }): Promise<InterviewBlueprint> {
    const { role, experience, skills, difficulty } = params;

    if (!role || typeof role !== 'string' || !role.trim()) {
      throw new Error('Role is required');
    }

    const cleanedSkills = Array.isArray(skills)
      ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
      : [];

    const skillList = cleanedSkills.length > 0 ? cleanedSkills.join(', ') : role.trim();
    const expNote = experience?.trim()
      ? `Experience: ${experience.trim()}`
      : 'Experience: Not specified';
    const diffNote = difficulty?.trim() || 'Medium';

    const prompt = `
You are an expert technical interviewer planning a realistic job interview.

Role: ${role.trim()}
${expNote}
Difficulty: ${diffNote}
Skills Context: ${skillList}

Task:
1. Dynamically determine 4 to 6 appropriate, realistic interview topics tailored specifically to this candidate's role and seniority.
   - For a junior candidate, focus on practical fundamentals, daily tools, implementation, and debugging.
   - For a senior candidate, include architecture, trade-offs, scalability, and system design.
   - For non-technical or specialized roles, adapt topics strictly to that profession.
2. Generate the first opening question for Topic 1 (max 1 natural spoken sentence).

Return structured JSON.
`;

    const schema = {
      type: Type.OBJECT,
      properties: {
        topics: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              name: { type: Type.STRING, description: 'Role-appropriate topic name (e.g. Flutter & Dart Basics, State Management, API Integration, Debugging)' },
              objective: { type: Type.STRING, description: 'What the interviewer evaluates in this topic.' },
            },
            required: ['name', 'objective'],
            additionalProperties: false,
          },
          description: '4 to 6 role-tailored interview topics.',
        },
        firstQuestion: {
          type: Type.STRING,
          description: 'A single, short, spoken opening question for the first topic (1 sentence max).',
        },
      },
      required: ['topics', 'firstQuestion'],
      additionalProperties: false,
    };

    console.log('[AIService] Generating role-tailored interview blueprint for:', role.trim());
    const result = await this.executeWithFallback(prompt, schema);

    const topics: InterviewTopic[] = Array.isArray(result.topics) && result.topics.length > 0
      ? result.topics.map((t: any) => ({
          name: String(t.name || 'Core Experience').trim(),
          objective: String(t.objective || 'Evaluate competency').trim(),
        }))
      : [
          { name: 'Practical Experience', objective: 'Understand recent development experience' },
          { name: 'Core Foundations', objective: 'Check technical foundation' },
          { name: 'State & Architecture', objective: 'Assess architecture decisions' },
          { name: 'Problem Solving', objective: 'Evaluate troubleshooting and debugging' },
          { name: 'Collaboration & Ownership', objective: 'Assess communication and ownership' },
        ];

    const firstQuestion = String(result.firstQuestion || '').trim() ||
      `To start off, could you tell me about a recent project you worked on as a ${role.trim()}?`;

    return { topics, firstQuestion };
  }

  /**
   * STAGE 2: Ultra-lightweight conversational turn.
   * Token-optimized: sends only compact memory summary and immediate Q&A context.
   */
  async getNextConversationalTurn(params: {
    role: string;
    currentTopic: string;
    topicObjective?: string;
    previousQuestion: string;
    candidateAnswer: string;
    conversationSummary: string;
    topicsRemaining: string[];
    followUpsUsed: number;
  }): Promise<ConversationalTurn> {
    const {
      role,
      currentTopic,
      topicObjective = '',
      previousQuestion,
      candidateAnswer,
      conversationSummary,
      topicsRemaining,
      followUpsUsed,
    } = params;

    const cleanedAnswer = candidateAnswer.trim() || 'No answer provided.';
    const nextTopicName = topicsRemaining[0] || currentTopic;

    const prompt = `
Interviewer for: ${role}
Current Topic: ${currentTopic} (${topicObjective})
Memory: "${conversationSummary || 'Start of interview'}"

Last Q: "${previousQuestion}"
Candidate A: "${cleanedAnswer}"
Follow-ups used on this topic: ${followUpsUsed} (max 1)
Next topic if moving on: "${nextTopicName}"

Task:
1. acknowledgement: 1-4 words natural reaction (e.g. "Got it.", "That makes sense.", "Interesting.", "Alright.") or "" (avoid repeating same reaction).
2. action: "follow_up" (ONLY if followUpsUsed == 0 and candidate gave an incomplete/interesting point) OR "new_topic" (if answer was sufficient or follow-up was already used).
3. nextQuestion: EXACTLY ONE short, natural spoken question (max 15 words).
4. nextTopic: "${currentTopic}" if follow_up, or "${nextTopicName}" if new_topic.
5. conversationSummary: updated compact 1-2 sentence memory of candidate's answers.
`;

    const schema = {
      type: Type.OBJECT,
      properties: {
        acknowledgement: {
          type: Type.STRING,
          description: 'Short natural reaction (1-4 words or empty string).',
        },
        action: {
          type: Type.STRING,
          enum: ['follow_up', 'new_topic'],
          description: 'Follow-up or transition to next topic.',
        },
        nextQuestion: {
          type: Type.STRING,
          description: 'Single short natural question (max 15 words).',
        },
        nextTopic: {
          type: Type.STRING,
          description: 'Topic name.',
        },
        conversationSummary: {
          type: Type.STRING,
          description: 'Updated 1-2 sentence memory summary.',
        },
      },
      required: ['acknowledgement', 'action', 'nextQuestion', 'nextTopic', 'conversationSummary'],
      additionalProperties: false,
    };

    const result = await this.executeWithFallback(prompt, schema);

    return {
      acknowledgement: String(result.acknowledgement ?? '').trim(),
      action: result.action === 'follow_up' && followUpsUsed < 1 ? 'follow_up' : 'new_topic',
      nextQuestion: String(result.nextQuestion ?? '').trim(),
      nextTopic: String(result.nextTopic ?? currentTopic).trim(),
      conversationSummary: String(result.conversationSummary ?? conversationSummary).trim(),
    };
  }

  /**
   * STAGE 3: Final evaluation after interview ends with dynamic, role-tailored skill metrics.
   */
  async generateFinalEvaluation(params: {
    role: string;
    experience?: string;
    difficulty?: string;
    skills?: string[];
    transcript: TranscriptEntry[];
  }): Promise<FinalInterviewEvaluation> {
    const { role, experience, difficulty, skills, transcript } = params;

    if (!transcript || transcript.length === 0) {
      throw new Error('Interview transcript is required for final evaluation');
    }

    const transcriptFormatted = transcript
      .map((item, idx) => `[Turn ${idx + 1}] (${item.topic})\nInterviewer: ${item.question}\nCandidate: ${item.answer || 'No response.'}`)
      .join('\n\n');

    const skillList = skills && skills.length > 0 ? skills.join(', ') : role;

    const prompt = `
You are the Lead Hiring Manager evaluating a candidate's complete interview scorecard.

Role: ${role}
Experience: ${experience || 'Not specified'}
Difficulty: ${difficulty || 'Medium'}
Skill Context: ${skillList}

INTERVIEW TRANSCRIPT:
${transcriptFormatted}

EVALUATION INSTRUCTIONS:
1. OVERALL SCORE: 0 to 100 based strictly on candidate's answers and technical depth shown.
2. PERFORMANCE LEVEL: "Excellent" (85-100), "Good" (70-84), "Average" (55-69), or "Needs Improvement" (<55).
3. SUMMARY: 2-3 sentence executive debrief on candidate competence and readiness.
4. STRENGTHS: 3 to 5 concrete strengths demonstrated during the interview.
5. AREAS TO IMPROVE: 3 to 5 actionable areas for growth.
6. SKILL PERFORMANCE: Generate 4 to 6 skill assessment scores (0-100) dynamically tailored to this specific role (e.g. for Flutter: "Flutter & Dart", "State Management", "API & Async", "Debugging", "UI Architecture").
7. RECOMMENDATIONS: 3 to 4 specific study topics or practical drills for next steps.
8. QUESTION REVIEWS: For each question asked, give a score (0-100) and 1 sentence of constructive feedback.
`;

    const schema = {
      type: Type.OBJECT,
      properties: {
        overallScore: { type: Type.INTEGER, description: 'Overall score from 0 to 100.' },
        performanceLevel: {
          type: Type.STRING,
          enum: ['Excellent', 'Good', 'Average', 'Needs Improvement'],
          description: 'Overall performance level.',
        },
        summary: { type: Type.STRING, description: 'Executive debrief paragraph.' },
        strengths: {
          type: Type.ARRAY,
          items: { type: Type.STRING },
          description: '3-5 key candidate strengths.',
        },
        areasToImprove: {
          type: Type.ARRAY,
          items: { type: Type.STRING },
          description: '3-5 areas for improvement.',
        },
        skillPerformance: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              skill: { type: Type.STRING, description: 'Name of the skill competency tailored to this role.' },
              score: { type: Type.INTEGER, description: 'Score between 0 and 100.' },
            },
            required: ['skill', 'score'],
            additionalProperties: false,
          },
          description: '4 to 6 role-tailored skill scores.',
        },
        recommendations: {
          type: Type.ARRAY,
          items: { type: Type.STRING },
          description: 'Recommended study topics or drills.',
        },
        questionReviews: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              question: { type: Type.STRING },
              answer: { type: Type.STRING },
              feedback: { type: Type.STRING },
              score: { type: Type.INTEGER },
            },
            required: ['question', 'answer', 'feedback', 'score'],
            additionalProperties: false,
          },
          description: 'Turn-by-turn question reviews.',
        },
      },
      required: [
        'overallScore',
        'performanceLevel',
        'summary',
        'strengths',
        'areasToImprove',
        'skillPerformance',
        'recommendations',
        'questionReviews',
      ],
      additionalProperties: false,
    };

    console.log('[AIService] Generating role-tailored final evaluation for', transcript.length, 'turns.');
    const result = await this.executeWithFallback(prompt, schema);

    const clamp = (val: any) => Math.max(0, Math.min(100, Math.round(Number(val) || 0)));

    // Map dynamic skill array into Record<string, number>
    const skillPerformance: Record<string, number> = {};
    if (Array.isArray(result.skillPerformance)) {
      for (const item of result.skillPerformance) {
        if (item && item.skill) {
          skillPerformance[String(item.skill).trim()] = clamp(item.score);
        }
      }
    }

    // Default fallback if array was empty
    if (Object.keys(skillPerformance).length === 0) {
      skillPerformance[`${role} Core`] = clamp(result.overallScore);
      skillPerformance['Problem Solving'] = clamp(result.overallScore);
      skillPerformance['Communication'] = clamp(result.overallScore);
    }

    const questionReviews: QuestionReview[] = Array.isArray(result.questionReviews)
      ? result.questionReviews.map((qr: any) => ({
          question: String(qr.question || '').trim(),
          answer: String(qr.answer || '').trim(),
          feedback: String(qr.feedback || '').trim(),
          score: clamp(qr.score),
        }))
      : [];

    return {
      overallScore: clamp(result.overallScore),
      performanceLevel: result.performanceLevel ?? 'Good',
      summary: String(result.summary ?? '').trim(),
      strengths: Array.isArray(result.strengths) ? result.strengths.map((s: any) => String(s).trim()) : [],
      areasToImprove: Array.isArray(result.areasToImprove) ? result.areasToImprove.map((s: any) => String(s).trim()) : [],
      skillPerformance,
      recommendations: Array.isArray(result.recommendations) ? result.recommendations.map((s: any) => String(s).trim()) : [],
      questionReviews,
    };
  }
}

export const aiService = new AIService();