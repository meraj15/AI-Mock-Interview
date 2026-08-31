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
  'gemini-3.5-flash-lite',
  'gemini-3.6-flash',
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
        throw new Error(
          'GEMINI_API_KEY is not configured',
        );
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

    for (
      let index = 0;
      index < FALLBACK_MODELS.length;
      index++
    ) {
      const model = FALLBACK_MODELS[index];

      const hasNext =
        index < FALLBACK_MODELS.length - 1;

      try {
        console.log(
          `[AIService] Calling model: ${model}`,
        );

        response =
          await client.models.generateContent({
            model,
            contents: prompt,

            config: {
              responseMimeType:
                'application/json',

              responseSchema: schema,

              // Slight creativity for natural/random interviews.
              temperature: 0.8,

              topP: 0.9,
            },
          });

        console.log(
          `[AIService] Model ${model} succeeded`,
        );

        lastError = null;

        break;
      } catch (err: any) {
        console.error(
          `[AIService] Model ${model} failed:`,
          err?.message || err,
        );

        lastError = err;

        if (
          this.isTemporaryError(err) &&
          hasNext
        ) {
          console.log(
            '[AIService] Trying fallback model...',
          );

          continue;
        }

        throw new Error(
          `Gemini API Error: ${
            err?.message ||
            JSON.stringify(err)
          }`,
        );
      }
    }

    if (!response) {
      throw new Error(
        `All Gemini models failed. Last error: ${
          lastError?.message ||
          JSON.stringify(lastError)
        }`,
      );
    }

    const text = response.text?.trim();

    if (!text) {
      throw new Error(
        'Gemini returned an empty response',
      );
    }

    try {
      return JSON.parse(text);
    } catch {
      throw new Error(
        `Gemini returned invalid JSON: ${text.slice(
          0,
          500,
        )}`,
      );
    }
  }

  // ==========================================================
  // STAGE 1
  //
  // ONLY GENERATE THE FIRST QUESTION.
  //
  // DO NOT GENERATE 5 QUESTIONS.
  // ==========================================================

  async generateInterviewPlan(params: {
    role: string;
    experience?: string;
    skills?: string[];
    difficulty?: string;
    questionCount?: number;
  }): Promise<InterviewBlueprint> {
    const {
      role,
      experience,
      skills,
      difficulty,
    } = params;

    if (
      !role ||
      typeof role !== 'string' ||
      !role.trim()
    ) {
      throw new Error('Role is required');
    }

    const cleanedSkills = Array.isArray(skills)
      ? skills
          .filter(
            (skill) =>
              typeof skill === 'string' &&
              skill.trim(),
          )
          .map((skill) => skill.trim())
      : [];

    const skillList =
      cleanedSkills.length > 0
        ? cleanedSkills.join(', ')
        : 'No specific skills provided';

    const experienceText =
      experience?.trim() ||
      'Experience not specified';

    const difficultyText =
      difficulty?.trim() || 'Medium';

    const prompt = `
You are a real human interviewer starting a live
technical job interview.

CANDIDATE

Role:
${role.trim()}

Experience:
${experienceText}

Skills:
${skillList}

Difficulty:
${difficultyText}

Your task is ONLY to start the interview.

Do NOT generate a list of questions.

Generate exactly ONE opening question.

The opening question should:

- Be short.
- Be natural when spoken aloud.
- Sound like a real interviewer.
- Match the candidate's experience.
- Match the selected difficulty.
- Be relevant to the role.
- NOT necessarily use one of the listed skills.
- Prefer practical or experience-based questions.
- Avoid textbook wording.
- Avoid long questions.
- Maximum 15 words.

The interviewer should NOT sound robotic.

For example:

"Could you tell me about a recent project you worked on?"

or

"What was the most challenging part of your last project?"

Do NOT always use the same opening pattern.

Also identify 4-6 broad areas the interviewer could potentially
explore later.

IMPORTANT:

These are NOT a fixed question sequence.

The interviewer must decide dynamically what to ask next
based on the candidate's answers.

Return ONLY JSON.
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        topics: {
          type: Type.ARRAY,

          items: {
            type: Type.OBJECT,

            properties: {
              name: {
                type: Type.STRING,
              },

              objective: {
                type: Type.STRING,
              },
            },

            required: [
              'name',
              'objective',
            ],

            additionalProperties: false,
          },
        },

        firstQuestion: {
          type: Type.STRING,
        },
      },

      required: [
        'topics',
        'firstQuestion',
      ],

      additionalProperties: false,
    };

    console.log(
      '[AIService] Creating interview session...',
    );

    const result =
      await this.executeWithFallback(
        prompt,
        schema,
      );

    const topics: InterviewTopic[] =
      Array.isArray(result.topics)
        ? result.topics
            .map((topic: any) => ({
              name: String(
                topic?.name ||
                  'General Technical Discussion',
              ).trim(),

              objective: String(
                topic?.objective ||
                  'Evaluate candidate competence',
              ).trim(),
            }))
            .filter(
              (topic: InterviewTopic) =>
                topic.name.length > 0,
            )
        : [];

    const firstQuestion =
      String(
        result.firstQuestion || '',
      ).trim();

    if (!firstQuestion) {
      throw new Error(
        'Gemini failed to generate the first question',
      );
    }

    return {
      topics,
      firstQuestion,
    };
  }

  // ==========================================================
  // STAGE 2
  //
  // THIS IS THE IMPORTANT PART.
  //
  // Called AFTER EVERY ANSWER.
  // ==========================================================

  async getNextConversationalTurn(params: {
    role: string;

    experience?: string;

    skills?: string[];

    difficulty?: string;

    currentTopic: string;

    topicObjective?: string;

    previousQuestion: string;

    candidateAnswer: string;

    conversationSummary: string;

    topicsCovered: string[];

    topicsRemaining: string[];

    followUpsUsed: number;

    recentQuestions?: string[];

    turnNumber?: number;

    maxTurns?: number;
  }): Promise<ConversationalTurn> {
    const {
      role,
      experience,
      skills,
      difficulty,
      currentTopic,
      topicObjective,
      previousQuestion,
      candidateAnswer,
      conversationSummary,
      topicsCovered,
      topicsRemaining,
      followUpsUsed,
      recentQuestions,
      turnNumber,
      maxTurns,
    } = params;

    const cleanedAnswer =
      candidateAnswer?.trim() ||
      'The candidate gave little or no response.';

    const skillList =
      skills && skills.length > 0
        ? skills.join(', ')
        : 'General role knowledge';

    const recentQuestionList =
      recentQuestions &&
      recentQuestions.length > 0
        ? recentQuestions
            .slice(-8)
            .map(
              (q, index) =>
                `${index + 1}. ${q}`,
            )
            .join('\n')
        : 'None';

    const remainingTopics =
      topicsRemaining &&
      topicsRemaining.length > 0
        ? topicsRemaining.join(', ')
        : 'No predefined topics remaining';

    const prompt = `
You are a REAL HUMAN technical interviewer
having a live spoken interview.

You have just listened to the candidate's answer.

Your job is to decide what the interviewer should say NEXT.

==================================================
CANDIDATE
==================================================

Role:
${role}

Experience:
${experience || 'Not specified'}

Difficulty:
${difficulty || 'Medium'}

Skills:
${skillList}

==================================================
CURRENT CONVERSATION
==================================================

Current topic:
${currentTopic}

Topic objective:
${topicObjective || 'Evaluate technical competence'}

Previous question:
"${previousQuestion}"

Candidate answer:
"${cleanedAnswer}"

Compact conversation memory:
"${conversationSummary || 'No previous memory.'}"

Topics already discussed:
${topicsCovered.join(', ') || 'None'}

Possible topics:
${remainingTopics}

Follow-ups already used on current topic:
${followUpsUsed}

Interview turn:
${turnNumber || 1}

Maximum turns:
${maxTurns || 10}

==================================================
RECENT QUESTIONS
==================================================

${recentQuestionList}

==================================================
MOST IMPORTANT RULE
==================================================

DO NOT behave like a fixed question list.

The next question must be selected dynamically.

Think like an experienced interviewer.

First understand the candidate's answer.

Then decide whether the candidate's answer creates a
useful opportunity for a follow-up.

==================================================
OPTION 1 — FOLLOW UP
==================================================

Choose "follow_up" when:

- The answer contains an interesting technical detail.
- The candidate made an important claim.
- The candidate's reasoning needs clarification.
- The answer is incomplete.
- The interviewer can naturally go one level deeper.
- A practical trade-off should be explored.

A follow-up should feel directly connected to
what the candidate just said.

Example:

Candidate:
"I used Riverpod because it made state management easier."

Good follow-up:

"What made Riverpod a better choice for that project?"

Bad:

"What are the advantages of Riverpod?"

==================================================
OPTION 2 — NEW TOPIC
==================================================

Choose "new_topic" when:

- The candidate answered clearly.
- The current topic has already been explored.
- There is no valuable follow-up.
- The interviewer should change direction.
- A fresh question would provide better evaluation.

The new question can be:

- technical
- practical
- debugging
- problem solving
- architecture
- performance
- experience
- behavioral

It does NOT need to directly match a listed skill.

==================================================
RANDOMNESS
==================================================

The interview should NOT follow a predictable sequence.

Do NOT always do:

Question → Follow-up → New topic → Follow-up.

Sometimes:

Question → New topic.

Sometimes:

Question → Follow-up → Follow-up is NOT allowed.

Sometimes:

Question → New topic → New topic.

The decision must depend on the candidate's answer.

==================================================
FOLLOW-UP LIMIT
==================================================

Maximum ONE follow-up on the same topic.

If:

followUpsUsed >= 1

you MUST choose:

"new_topic"

==================================================
QUESTION VARIETY
==================================================

Never repeat a recent question.

Do NOT ask a slightly rewritten version of a previous question.

Avoid repeated patterns.

For example, do NOT ask:

"What is Provider?"

then:

"What is Riverpod?"

then:

"What is Firebase?"

That feels like an exam.

Instead vary naturally:

"Why did you choose that approach?"

"How would you debug that?"

"What would happen if the API failed?"

"Tell me about a difficult issue you faced."

"How would you improve that implementation?"

==================================================
QUESTION LENGTH
==================================================

The next question MUST be:

- One sentence.
- Short.
- Spoken naturally.
- Maximum 15 words.
- Prefer 6-12 words.
- No multi-part questions.
- No essay-style questions.

==================================================
ACKNOWLEDGEMENT
==================================================

Optionally respond naturally before the question.

Examples:

"Got it."

"Okay."

"That makes sense."

"Interesting."

"Right."

"I see."

"Good."

"Alright."

"That's fair."

Sometimes use an empty acknowledgement.

IMPORTANT:

Do NOT use the same acknowledgement repeatedly.

Keep it under 4 words.

==================================================
CONVERSATION MEMORY
==================================================

Update the summary with only useful information learned
from the candidate.

Keep it short.

Maximum 2 sentences.

Do NOT copy the candidate's entire answer.

==================================================
TOPIC
==================================================

If choosing follow_up:

nextTopic should normally remain:

${currentTopic}

If choosing new_topic:

choose a genuinely different topic.

Do NOT always select the first remaining topic.

==================================================
FINAL TURN
==================================================

If the interview is close to its maximum turn count,
prefer a new topic that gives strong overall evaluation.

Do not unnecessarily start a deep follow-up when there
is not enough room for it.

==================================================
OUTPUT
==================================================

Return ONLY JSON.

{
  "acknowledgement": "...",
  "action": "follow_up" | "new_topic",
  "nextQuestion": "...",
  "nextTopic": "...",
  "conversationSummary": "..."
}
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        acknowledgement: {
          type: Type.STRING,

          description:
            'Very short natural interviewer reaction or empty string.',
        },

        action: {
          type: Type.STRING,

          enum: [
            'follow_up',
            'new_topic',
          ],
        },

        nextQuestion: {
          type: Type.STRING,

          description:
            'Short natural spoken interview question, maximum 15 words.',
        },

        nextTopic: {
          type: Type.STRING,

          description:
            'Topic for the next question.',
        },

        conversationSummary: {
          type: Type.STRING,

          description:
            'Short 1-2 sentence memory of useful candidate information.',
        },
      },

      required: [
        'acknowledgement',
        'action',
        'nextQuestion',
        'nextTopic',
        'conversationSummary',
      ],

      additionalProperties: false,
    };

    const result =
      await this.executeWithFallback(
        prompt,
        schema,
      );

    let action =
      result.action === 'follow_up'
        ? 'follow_up'
        : 'new_topic';

    // Hard safety rule.
    if (followUpsUsed >= 1) {
      action = 'new_topic';
    }

    let nextQuestion =
      String(
        result.nextQuestion || '',
      ).trim();

    let nextTopic =
      String(
        result.nextTopic ||
          currentTopic,
      ).trim();

    let acknowledgement =
      String(
        result.acknowledgement || '',
      ).trim();

    const summary =
      String(
        result.conversationSummary ||
          conversationSummary ||
          '',
      ).trim();

    // ----------------------------------------------------------
    // Safety cleanup
    // ----------------------------------------------------------

    if (acknowledgement.length > 40) {
      acknowledgement =
        acknowledgement
          .split(/\s+/)
          .slice(0, 4)
          .join(' ');
    }

    if (!nextQuestion) {
      throw new Error(
        'Gemini failed to generate next interview question',
      );
    }

    if (!nextTopic) {
      nextTopic = currentTopic;
    }

    return {
      acknowledgement,

      action: action as
        | 'follow_up'
        | 'new_topic',

      nextQuestion,

      nextTopic,

      conversationSummary:
        summary,
    };
  }

  // ==========================================================
  // STAGE 3
  //
  // FINAL EVALUATION
  //
  // ONLY CALL ONCE AFTER INTERVIEW ENDS.
  // ==========================================================

  async generateFinalEvaluation(params: {
    role: string;

    experience?: string;

    difficulty?: string;

    skills?: string[];

    transcript: TranscriptEntry[];
  }): Promise<FinalInterviewEvaluation> {
    const {
      role,
      experience,
      difficulty,
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
      skills && skills.length > 0
        ? skills.join(', ')
        : role;

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
You are a senior hiring manager evaluating
a completed technical mock interview.

ROLE:
${role}

EXPERIENCE:
${experience || 'Not specified'}

DIFFICULTY:
${difficulty || 'Medium'}

SKILLS CONTEXT:
${skillList}

==================================================
FULL INTERVIEW
==================================================

${transcriptFormatted}

==================================================
EVALUATION
==================================================

Evaluate ONLY what the candidate actually demonstrated.

Do not assume knowledge that was not demonstrated.

Consider:

- Technical knowledge
- Practical understanding
- Problem solving
- Debugging ability
- Architecture and design thinking
- Communication
- Role readiness
- Quality of reasoning
- Ability to explain decisions

Do NOT punish a candidate simply because a topic
was not asked.

==================================================
OVERALL SCORE
==================================================

0-100.

Excellent: 85-100
Good: 70-84
Average: 55-69
Needs Improvement: below 55

==================================================
SUMMARY
==================================================

Write a professional 2-3 sentence summary.

==================================================
STRENGTHS
==================================================

Provide 3-5 concrete strengths demonstrated
during the interview.

==================================================
AREAS TO IMPROVE
==================================================

Provide 3-5 actionable improvements.

==================================================
SKILL PERFORMANCE
==================================================

Score these dimensions from 0-100:

Technical Knowledge
Problem Solving
Architecture & Design
Communication & Clarity
Role Mastery

==================================================
RECOMMENDATIONS
==================================================

Provide 3-4 practical study topics or exercises.

==================================================
QUESTION REVIEWS
==================================================

For every interviewer question:

- include the question
- include candidate answer
- score from 0-100
- provide one concise feedback sentence

Return ONLY JSON.
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

    const result =
      await this.executeWithFallback(
        prompt,
        schema,
      );

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

export const aiService =
  new AIService();