
import { GoogleGenAI, Type } from '@google/genai';
import { config } from '../config';

// ============================================================
// TYPES
// ============================================================

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
  action: 'follow_up' | 'new_topic' | 'end_interview';
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

  performanceLevel:
    | 'Excellent'
    | 'Good'
    | 'Average'
    | 'Needs Improvement';

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

// ============================================================
// MODELS
// ============================================================

const FALLBACK_MODELS = [
  'gemini-3.7-flash',
  'gemini-3.6-flash',
  'gemini-flash-latest',
];

// ============================================================
// AI SERVICE
// ============================================================

export class AIService {
  private client: GoogleGenAI | null = null;

  // ==========================================================
  // CLIENT
  // ==========================================================

  private getClient(): GoogleGenAI {
    if (!this.client) {
      if (!config.gemini.apiKey?.trim()) {
        throw new Error('GEMINI_API_KEY is not configured');
      }

      this.client = new GoogleGenAI({
        apiKey: config.gemini.apiKey.trim(),
      });
    }

    return this.client;
  }

  // ==========================================================
  // TEMPORARY ERROR CHECK
  // ==========================================================

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
      status === 429 ||
      status === 503 ||
      status === '429' ||
      status === '503' ||
      status === 'UNAVAILABLE' ||
      status === 'RESOURCE_EXHAUSTED'
    ) {
      return true;
    }

    const message = (
      typeof err === 'string'
        ? err
        : errorObj?.message ||
          errorObj?.error?.message ||
          JSON.stringify(err)
    ).toLowerCase();

    return [
      '429',
      '503',
      'rate limit',
      'resource exhausted',
      'unavailable',
      'overloaded',
      'high demand',
      'temporarily unavailable',
    ].some((value) => message.includes(value));
  }

  // ==========================================================
  // GEMINI EXECUTOR
  // ==========================================================

  private async executeWithFallback(
    prompt: string,
    schema: any,
  ): Promise<any> {
    const client = this.getClient();

    let response: any = null;
    let lastError: any = null;
    let usedModel = FALLBACK_MODELS[0];

    for (
      let index = 0;
      index < FALLBACK_MODELS.length;
      index++
    ) {
      const model = FALLBACK_MODELS[index];
      const hasNext = index < FALLBACK_MODELS.length - 1;

      try {
        console.log(`[AIService] Calling model: ${model}`);

        response = await client.models.generateContent({
          model,
          contents: prompt,
          config: {
            responseMimeType: 'application/json',
            responseSchema: schema,
            temperature: 0.8,
            topP: 0.9,
          },
        });

        usedModel = model;
        lastError = null;
        break;
      } catch (err: any) {
        console.error(`[AIService] Model ${model} failed:`, err?.message || err);
        lastError = err;

        if (this.isTemporaryError(err) && hasNext) {
          console.log('[AIService] Temporary error — waiting 200ms before fallback...');
          await new Promise((r) => setTimeout(r, 200));
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
    if (!text) throw new Error('Gemini returned an empty response');

    try {
      return JSON.parse(text);
    } catch {
      throw new Error(`Gemini returned invalid JSON: ${text.slice(0, 500)}`);
    }
  }

  // ==========================================================
  // TIMEOUT WRAPPER
  //
  // Wraps a Gemini call in a hard deadline.
  // NOTE: Promise.race() does not cancel the underlying HTTP
  // request — it only lets your code move forward. True
  // cancellation requires AbortSignal support in @google/genai.
  // Check package version before switching to AbortController.
  // ==========================================================

  private async executeWithTimeout<T>(
    fn: () => Promise<T>,
    timeoutMs: number,
    label: string,
  ): Promise<T> {
    let timer: NodeJS.Timeout;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error(`[AIService] ${label} timed out after ${timeoutMs}ms`)),
        timeoutMs,
      );
    });
    try {
      return await Promise.race([fn(), timeoutPromise]);
    } finally {
      clearTimeout(timer!);
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  private cleanSkills(
    skills?: string[],
  ): string[] {
    return Array.isArray(skills)
      ? skills
          .filter(
            (skill) =>
              typeof skill === 'string' &&
              skill.trim().length > 0,
          )
          .map((skill) => skill.trim())
      : [];
  }

  private getSkillList(
    skills?: string[],
  ): string {
    const cleanedSkills =
      this.cleanSkills(skills);

    return cleanedSkills.length > 0
      ? cleanedSkills.join(', ')
      : 'No specific skills provided';
  }

  private enforceSingleQuestion(rawQuestion: string, fallback: string): string {
    let q = (rawQuestion || '').trim().replace(/^["']|["']$/g, '');
    if (!q) return fallback;

    // Strip out conversational reactions / acknowledgements if the model accidentally prepended them to nextQuestion
    q = q.replace(
      /^(Understood[.,!]?|Got it,?( that makes sense)?[.,!]?|Makes (total )?sense[.,!]?|Fair (point|enough)[.,!]?|Right on[.,!]?|Thank you[.,!]?|Thanks for (sharing|that)[.,!]?|Certainly!?|Sure!?|Alright,?|Okay,?|Now,?|Moving on,?|Next question:?)\s*/i,
      '',
    );

    // If there are multiple question marks, extract the first complete question
    if (q.includes('?')) {
      const parts = q.split('?');
      if (parts.length > 2) {
        q = parts[0].trim() + '?';
      }
    }

    // Ensure it ends with a question mark if it's an inquiry
    if (!q.endsWith('?') && !q.endsWith('!')) {
      if (q.match(/^(can|could|how|what|why|where|when|which|tell|walk|explain)/i)) {
        q = q.replace(/[.,;:]+$/, '') + '?';
      }
    }

    // Clean up compound questions joined with "and how / and why / and what"
    q = q.replace(/,\s*and\s+(how|why|what|can|could|where)\b.*\?/i, '?');

    return q;
  }

  // ==========================================================
  // STAGE 1
  //
  // Generate only the first question.
  //
  // Role-based warm introduction question.
  // ==========================================================

  async generateInterviewPlan(params: {
    role: string;
    experience?: string;
    skills?: string[];
    questionCount?: number;
  }): Promise<InterviewBlueprint> {
    const { role, experience, skills } = params;

    if (!role || typeof role !== 'string' || !role.trim()) {
      throw new Error('Role is required');
    }

    const skillList = this.getSkillList(skills);
    const experienceText = experience?.trim() || 'Not specified';

    const prompt = `You are a senior interviewer opening a live, realistic interview.

GLOBAL RULE: This is a general-purpose AI interview platform. Conduct a realistic interview for the candidate's target role. Never assume a specific technology or domain unless explicitly stated in the role or profile.

ROLE: ${role.trim()}
EXPERIENCE: ${experienceText}
BACKGROUND SKILLS (context only — do not restrict to these): ${skillList}

Generate exactly ONE warm opening question:
- Welcome the candidate and ask them to introduce their background as a ${role.trim()}.
- Do NOT ask a technical question in this opening turn.
- Maximum 18 words. Exactly one question mark.

Examples:
"Welcome! Could you introduce yourself and walk me through your background as a ${role.trim()}?"
"Hi, welcome! Please introduce yourself and share your journey as a ${role.trim()}."

Return ONLY valid JSON.`;

    const schema = {
      type: Type.OBJECT,
      properties: {
        firstQuestion: {
          type: Type.STRING,
          description: 'Warm opening question. Max 18 words. Exactly one question mark.',
        },
      },
      required: ['firstQuestion'],
      additionalProperties: false,
    };

    console.log(`[AIService] generateInterviewPlan | role="${role.trim()}"`);
    const t0 = Date.now();

    const result = await this.executeWithTimeout(
      () => this.executeWithFallback(prompt, schema),
      20_000,
      'generateInterviewPlan',
    );

    console.log(`[AIService] generateInterviewPlan | latency=${Date.now() - t0}ms`);

    const defaultFirstQ = `Welcome! Could you introduce yourself and share your background as a ${role.trim()}?`;
    const firstQuestion = this.enforceSingleQuestion(
      String(result.firstQuestion || '').trim(),
      defaultFirstQ,
    );

    return { topics: [], firstQuestion };
  }

  // generateTopics() removed — topic areas are now chosen dynamically
  // by the AI inside getNextConversationalTurn() on each answer turn.

  // ==========================================================
  // STAGE 2
  //
  // Called AFTER EVERY ANSWER.
  //
  // Fully adaptive — the AI chooses the next evaluation area
  // based on the candidate's role, profile, and prior answers.
  // No pre-generated topic pool is used.
  // ==========================================================

  async getNextConversationalTurn(params: {
    role: string;
    experience?: string;
    skills?: string[];

    previousQuestion: string;
    candidateAnswer: string;

    conversationSummary: string;
    areasExplored: string[];

    followUpsUsed: number;
    recentQuestions?: string[];

    turnNumber?: number;
    maxTurns?: number;
  }): Promise<ConversationalTurn> {
    const {
      role,
      experience,
      skills,
      previousQuestion,
      candidateAnswer,
      conversationSummary,
      areasExplored,
      followUpsUsed,
      recentQuestions,
      turnNumber,
      maxTurns,
    } = params;

    const cleanedAnswer = candidateAnswer?.trim() || 'The candidate gave little or no response.';
    const skillList = this.getSkillList(skills);

    const recentQuestionList = recentQuestions && recentQuestions.length > 0
      ? recentQuestions.slice(-5).map((q, i) => `${i + 1}. ${q}`).join('\n')
      : 'None';

    const exploredList = areasExplored.length > 0 ? areasExplored.join(', ') : 'None yet';

    const currentTurn = turnNumber || 1;
    const totalMaxTurns = maxTurns || 8;
    const isIntroTransition = currentTurn === 1;
    const isPenultimateTurn = currentTurn === totalMaxTurns - 1;
    const isFinalClosingTurn = currentTurn >= totalMaxTurns;

    // Compact stage tag + constraint (replaces the old 20-line stageInstructions block)
    let stageTag: string;
    let stageConstraint: string;

    if (isFinalClosingTurn) {
      stageTag = 'FINAL_FAREWELL';
      stageConstraint = `action MUST be "end_interview". nextQuestion must be a warm closing farewell — no technical question. nextTopic: "Interview Conclusion".`;
    } else if (isPenultimateTurn) {
      stageTag = 'PENULTIMATE';
      stageConstraint = `This is the last technical question. Naturally signal to the candidate that we are wrapping up. One question mark, max 18 words.`;
    } else if (isIntroTransition) {
      stageTag = 'INTRO_TO_TECHNICAL';
      stageConstraint = `Candidate just gave their intro. Pick ONE specific tool, experience, or scenario they mentioned and ask a grounded first technical question for a ${role}. Never assume a technology not mentioned in the role or profile.`;
    } else {
      stageTag = 'CORE_TECHNICAL';
      stageConstraint = `Ask a practical, role-grounded question. If the answer was strong, go deeper into edge cases or trade-offs. If weak, smoothly pivot to another relevant area for a ${role}.`;
    }

    const prompt = `You are a senior interviewer conducting a live adaptive mock interview.

GLOBAL RULE: Conduct a realistic interview appropriate for the candidate's target role. Never assume a specific technology, profession, or domain unless explicitly stated in the role or profile. Skills listed are context only — base questions on the candidate's actual profession.

ROLE: ${role} | EXP: ${experience || 'not specified'} | TOOLS (context only): ${skillList}
STAGE: ${stageTag}   TURN: ${currentTurn}/${totalMaxTurns}   FOLLOWUPS_USED: ${followUpsUsed}

CURRENT QUESTION:
"${previousQuestion}"

CANDIDATE ANSWER:
"${cleanedAnswer}"

INTERVIEW MEMORY:
${conversationSummary || 'Interview just started.'}

AREAS ALREADY EXPLORED: ${exploredList}

RECENT QUESTIONS (do not repeat):
${recentQuestionList}

STAGE INSTRUCTION: ${stageConstraint}

RULES:
1. Exactly ONE question mark. Max 18 words. No compound questions.
2. acknowledgement: 2–4 spoken words only (TTS, never shown in UI).
3. nextTopic: choose a relevant evaluation area for a "${role}" not yet explored. Do not use a predefined list — pick what genuinely fits this role and this candidate.
4. action: follow_up | new_topic | end_interview

Return ONLY valid JSON.`;

    const schema = {
      type: Type.OBJECT,
      properties: {
        acknowledgement: {
          type: Type.STRING,
          description: 'Short spoken reaction (2–4 words). TTS only, never shown in UI.',
        },
        action: {
          type: Type.STRING,
          enum: ['follow_up', 'new_topic', 'end_interview'],
        },
        nextQuestion: {
          type: Type.STRING,
          description: 'Pure interview question only. No acknowledgement mixed in. Max 18 words. One "?".',
        },
        nextTopic: {
          type: Type.STRING,
          description: 'Relevant evaluation area for this specific role (not from a fixed list).',
        },
        conversationSummary: {
          type: Type.STRING,
          description: 'Short 1–2 sentence memory of candidate ability demonstrated so far.',
        },
      },
      required: ['acknowledgement', 'action', 'nextQuestion', 'nextTopic', 'conversationSummary'],
      additionalProperties: false,
    };

    const t0 = Date.now();
    const result = await this.executeWithTimeout(
      () => this.executeWithFallback(prompt, schema),
      15_000,
      'getNextConversationalTurn',
    );
    console.log(`[AIService] getNextConversationalTurn | latency=${Date.now() - t0}ms | turn=${currentTurn}/${totalMaxTurns}`);

    // ── Normalize ──────────────────────────────────────────────

    let action: 'follow_up' | 'new_topic' | 'end_interview' =
      result.action === 'end_interview' || isFinalClosingTurn
        ? 'end_interview'
        : result.action === 'follow_up'
        ? 'follow_up'
        : 'new_topic';

    const fallbackQuestion = isFinalClosingTurn
      ? `Thank you so much for your time today — that brings our interview to a close!`
      : isPenultimateTurn
      ? `For our final question, what's a challenging problem you recently solved in your role as a ${role}?`
      : isIntroTransition
      ? `To start on the technical side, what's a core tool or system you rely on most as a ${role}?`
      : `In your day-to-day work as a ${role}, how do you approach diagnosing unexpected issues?`;

    let nextQuestion = this.enforceSingleQuestion(
      String(result.nextQuestion || '').trim(),
      fallbackQuestion,
    );

    // Safety fallback for blank nextTopic
    const DEFAULT_AREA_FALLBACK = [
      'Core Technical Skills', 'Problem Solving', 'System Design',
      'Real-World Scenarios', 'Communication & Process',
    ];

    let nextTopic = String(
      result.nextTopic || (isFinalClosingTurn ? 'Interview Conclusion' : ''),
    ).trim();
    if (!nextTopic) {
      nextTopic = isFinalClosingTurn
        ? 'Interview Conclusion'
        : DEFAULT_AREA_FALLBACK[areasExplored.length % DEFAULT_AREA_FALLBACK.length];
    }

    let acknowledgement = String(result.acknowledgement || '').trim();
    if (acknowledgement.length > 40) {
      acknowledgement = acknowledgement.split(/\s+/).slice(0, 4).join(' ');
    }

    const summary = String(result.conversationSummary || conversationSummary || '').trim();

    // Max 2 follow-ups per area
    if (followUpsUsed >= 2 && action === 'follow_up') action = 'new_topic';
    if (!nextQuestion) nextQuestion = fallbackQuestion;

    return { acknowledgement, action, nextQuestion, nextTopic, conversationSummary: summary };
  }

  // ==========================================================
  // STAGE 3
  //
  // FINAL EVALUATION
  //
  // Called once after interview ends.
  // ==========================================================

  async generateFinalEvaluation(params: {
    role: string;
    experience?: string;
    skills?: string[];
    transcript: TranscriptEntry[];
  }): Promise<FinalInterviewEvaluation> {
    const {
      role,
      experience,
      skills,
      transcript,
    } = params;

    if (
      !transcript ||
      transcript.length === 0
    ) {
      throw new Error(
        'Interview transcript is required',
      );
    }

    const skillList =
      this.getSkillList(skills);

    const transcriptFormatted =
      transcript
        .map(
          (item, index) =>
            `[Turn ${index + 1}]
Topic: ${item.topic}
Type: ${item.type}
Interviewer: ${item.question}
Candidate: ${
              item.answer ||
              'No response captured.'
            }`,
        )
        .join('\n\n');

    const prompt = `
You are a senior hiring manager evaluating a completed mock interview for a ${role}.

ROLE:
${role}

EXPERIENCE:
${experience || 'Not specified'}

BACKGROUND SKILLS & TOOLS:
${skillList}

IMPORTANT:
The candidate's listed skills are background information only.
Evaluate the candidate based ONLY on what they actually demonstrated during the interview.
Do not assume the candidate knows something simply because it appears in their skills list.
Do not penalize the candidate because a particular topic was not asked.
Evaluate whether the candidate's demonstrated ability is appropriate for their stated experience level.

==================================================
FULL INTERVIEW
==============

${transcriptFormatted}

==================================================
EVALUATION CRITERIA
===================

Evaluate:

* Domain & technical proficiency for a ${role}
* Problem solving and diagnostic methodology
* Practical execution and technical judgment
* Practical development or operational ability
* Debugging, troubleshooting, or incident analysis
* System or process understanding
* Performance and quality judgment
* Communication and clarity
* Ability to explain decisions and trade-offs
* Role readiness and depth of understanding relative to experience

Base the evaluation ONLY on demonstrated evidence from the interview.

==================================================
OVERALL SCORE
=============

Score from 0-100.
The score should reflect the candidate's demonstrated ability relative to their experience level.

85-100: Excellent
70-84: Good
55-69: Average
Below 55: Needs Improvement

==================================================
SUMMARY
=======

Write a professional 2-3 sentence summary of the candidate's performance.

==================================================
STRENGTHS
=========

Provide 3-5 concrete strengths demonstrated during the interview.
Do not write generic strengths.

==================================================
AREAS TO IMPROVE
================

Provide 3-5 specific and actionable improvements.

==================================================
SKILL PERFORMANCE
=================

Score each dimension from 0-100:

Technical Knowledge
Problem Solving
Architecture & Design
Communication & Clarity
Role Mastery

Scores must be based on demonstrated evidence.

==================================================
RECOMMENDATIONS
===============

Provide 3-4 practical learning topics or exercises that would help the candidate improve as a ${role}.

==================================================
QUESTION REVIEWS
================

For every interviewer question:
* Include the question.
* Include the candidate's answer.
* Give a score from 0-100.
* Provide one concise feedback sentence.

Feedback must explain the quality of the candidate's actual answer.

Return ONLY valid JSON.
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        overallScore: {
          type: Type.INTEGER,
        },

        performanceLevel: {
          type: Type.STRING,

          enum: [
            'Excellent',
            'Good',
            'Average',
            'Needs Improvement',
          ],
        },

        summary: {
          type: Type.STRING,
        },

        strengths: {
          type: Type.ARRAY,

          items: {
            type: Type.STRING,
          },
        },

        areasToImprove: {
          type: Type.ARRAY,

          items: {
            type: Type.STRING,
          },
        },

        skillPerformance: {
          type: Type.OBJECT,

          properties: {
            'Technical Knowledge': {
              type: Type.INTEGER,
            },

            'Problem Solving': {
              type: Type.INTEGER,
            },

            'Architecture & Design': {
              type: Type.INTEGER,
            },

            'Communication & Clarity': {
              type: Type.INTEGER,
            },

            'Role Mastery': {
              type: Type.INTEGER,
            },
          },

          required: [
            'Technical Knowledge',
            'Problem Solving',
            'Architecture & Design',
            'Communication & Clarity',
            'Role Mastery',
          ],

          additionalProperties: false,
        },

        recommendations: {
          type: Type.ARRAY,

          items: {
            type: Type.STRING,
          },
        },

        questionReviews: {
          type: Type.ARRAY,

          items: {
            type: Type.OBJECT,

            properties: {
              question: {
                type: Type.STRING,
              },

              answer: {
                type: Type.STRING,
              },

              feedback: {
                type: Type.STRING,
              },

              score: {
                type: Type.INTEGER,
              },
            },

            required: [
              'question',
              'answer',
              'feedback',
              'score',
            ],

            additionalProperties: false,
          },
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

    console.log(
      `[AIService] Generating final evaluation for ${transcript.length} turns`,
    );

    const t0 = Date.now();
    const result = await this.executeWithTimeout(
      () => this.executeWithFallback(prompt, schema),
      60_000,
      'generateFinalEvaluation',
    );
    console.log(`[AIService] generateFinalEvaluation | latency=${Date.now() - t0}ms | turns=${transcript.length}`);

    // ----------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------

    const clamp = (
      value: any,
    ): number => {
      return Math.max(
        0,
        Math.min(
          100,
          Math.round(
            Number(value) || 0,
          ),
        ),
      );
    };

    // ----------------------------------------------------------
    // Skill performance
    // ----------------------------------------------------------

    const rawSkillPerformance =
      result.skillPerformance || {};

    const skillPerformance: Record<
      string,
      number
    > = {};

    for (
      const [key, value] of Object.entries(
        rawSkillPerformance,
      )
    ) {
      skillPerformance[key] =
        clamp(value);
    }

    if (
      skillPerformance['Flutter/Dart Role Mastery'] !== undefined &&
      skillPerformance['Role Mastery'] === undefined
    ) {
      skillPerformance['Role Mastery'] =
        skillPerformance['Flutter/Dart Role Mastery'];
    }

    // ----------------------------------------------------------
    // Question reviews
    // ----------------------------------------------------------

    const questionReviews:
      QuestionReview[] =
      Array.isArray(
        result.questionReviews,
      )
        ? result.questionReviews.map(
            (review: any) => ({
              question: String(
                review?.question ||
                  '',
              ).trim(),

              answer: String(
                review?.answer ||
                  '',
              ).trim(),

              feedback: String(
                review?.feedback ||
                  '',
              ).trim(),

              score: clamp(
                review?.score,
              ),
            }),
          )
        : [];

    // ----------------------------------------------------------
    // Final result
    // ----------------------------------------------------------

    return {
      overallScore:
        clamp(result.overallScore),

      performanceLevel:
        result.performanceLevel ||
        'Average',

      summary:
        String(
          result.summary || '',
        ).trim(),

      strengths:
        Array.isArray(
          result.strengths,
        )
          ? result.strengths.map(
              (value: any) =>
                String(value).trim(),
            )
          : [],

      areasToImprove:
        Array.isArray(
          result.areasToImprove,
        )
          ? result.areasToImprove.map(
              (value: any) =>
                String(value).trim(),
            )
          : [],

      skillPerformance,

      recommendations:
        Array.isArray(
          result.recommendations,
        )
          ? result.recommendations.map(
              (value: any) =>
                String(value).trim(),
            )
          : [],

      questionReviews,
    };
  }
}

// ============================================================
// SINGLETON
// ============================================================

export const aiService =
  new AIService();
