
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

export type AnswerQuality =
  | 'weak'
  | 'average'
  | 'strong'
  | 'excellent';

export interface ConversationalTurn {
  acknowledgement: string;
  action: 'follow_up' | 'new_topic';
  answerQuality: AnswerQuality;
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
              responseMimeType: 'application/json',
              responseSchema: schema,

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

  // ==========================================================
  // STAGE 1
  //
  // Generate only the first question.
  //
  // Difficulty is NOT provided by the user.
  // ==========================================================

  async generateInterviewPlan(params: {
    role: string;
    experience?: string;
    skills?: string[];
    questionCount?: number;
  }): Promise<InterviewBlueprint> {
    const {
      role,
      experience,
      skills,
    } = params;

    if (
      !role ||
      typeof role !== 'string' ||
      !role.trim()
    ) {
      throw new Error('Role is required');
    }

    const skillList =
      this.getSkillList(skills);

    const experienceText =
      experience?.trim() ||
      'Experience not specified';

    const prompt = `
You are a real human technical interviewer starting a live technical interview for a Flutter/Dart developer.

CANDIDATE PROFILE:
Role: ${role.trim()}
Experience: ${experienceText}
Background Skills: ${skillList}

FIRST QUESTION - CANDIDATE INTRODUCTION:

In every real interview, the first question MUST ALWAYS be an introduction question to break the ice and let the candidate introduce themselves.

Generate exactly ONE natural introduction question welcoming the candidate and asking them to introduce themselves and give a brief overview of their background and journey as a Flutter/Dart developer.

Examples of natural opening introduction questions:
* "Could you introduce yourself and briefly walk me through your background as a developer?"
* "To start off, please introduce yourself and tell me a bit about your journey."
* "Welcome! Could you give a quick introduction about yourself and your work with Flutter?"
* "Let's kick things off with a brief introduction of yourself and what you've been building."
* "To begin, could you introduce yourself and share a bit about your developer journey?"

CRITICAL REQUIREMENTS:
* The first question MUST ALWAYS be an introduction question asking the candidate to introduce themselves.
* Do NOT jump straight into technical trivia, coding problems, or deep technical questions on this first question.
* It must sound warm, conversational, and natural when spoken aloud by a real human interviewer.
* Keep it concise (maximum 18 words).
* Vary the wording naturally between sessions so it feels genuine and personal.

Return ONLY valid JSON.
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        firstQuestion: {
          type: Type.STRING,
        },
      },

      required: ['firstQuestion'],

      additionalProperties: false,
    };

    console.log(
      '[AIService] Generating first question...',
    );

    const result =
      await this.executeWithFallback(
        prompt,
        schema,
      );

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
      topics: [],
      firstQuestion,
    };
  }

  // ==========================================================
  // STAGE 1-B
  //
  // Generate broad interview topics.
  //
  // Skills are context only.
  // ==========================================================

  async generateTopics(params: {
    role: string;
    experience?: string;
    skills?: string[];
  }): Promise<InterviewTopic[]> {
    const {
      role,
      experience,
      skills,
    } = params;

    const skillList =
      this.getSkillList(skills);

    const prompt = `
You are a senior technical interviewer planning a realistic Flutter/Dart technical interview.

CANDIDATE:
Role: ${role.trim()}
Experience: ${experience?.trim() || 'Not specified'}
Background Skills: ${skillList}

IMPORTANT:

The candidate's listed skills are CONTEXT ONLY.

Do NOT treat the skills list as a whitelist of topics.

The interview should evaluate the candidate's overall ability as a Flutter/Dart developer and may ask questions from ANY relevant area of Flutter and Dart, even if the candidate did not explicitly list that topic as a skill.

Create 6-10 broad evaluation areas for the interview.

Possible areas include, but are not limited to:

DART:

* Language fundamentals
* OOP
* Null safety
* Collections
* Generics
* Extensions
* Mixins
* Futures
* async/await
* Streams
* Isolates
* Error handling

FLUTTER:

* Widget tree
* StatelessWidget
* StatefulWidget
* BuildContext
* Widget lifecycle
* Keys
* Widget rebuilding
* Rendering
* State management
* Navigation
* Forms
* App lifecycle
* Platform integration

APPLICATION DEVELOPMENT:

* REST APIs
* Networking
* JSON serialization
* Authentication
* Local storage
* Caching
* Offline handling
* Pagination
* Firebase
* Error handling

ENGINEERING:

* Clean Architecture
* Repository pattern
* Dependency injection
* SOLID principles
* Testing
* Debugging
* Performance optimization
* Memory management
* Security
* Release/debugging problems

REAL-WORLD PROBLEM SOLVING:

* API failures
* Slow applications
* Unexpected crashes
* Memory issues
* Large datasets
* Offline/online synchronization
* Architecture decisions
* Production debugging

Do not try to cover every possible area.

Select a balanced set of areas appropriate for the candidate's role and experience.

The experience level should influence the expected depth of questions, but it should NOT restrict the available topics.

Each topic must contain:

* name
* objective

The objective should explain what the interviewer wants to evaluate.

Return ONLY valid JSON.
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
      },

      required: ['topics'],

      additionalProperties: false,
    };

    console.log(
      '[AIService] Generating interview topics...',
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

    console.log(
      `[AIService] Topics generated: ${topics
        .map((topic) => topic.name)
        .join(', ')}`,
    );

    return topics;
  }

  // ==========================================================
  // STAGE 2
  //
  // Called AFTER EVERY ANSWER.
  //
  // This is the adaptive interviewer.
  // ==========================================================

  async getNextConversationalTurn(params: {
    role: string;
    experience?: string;
    skills?: string[];

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
      this.getSkillList(skills);

    const recentQuestionList =
      recentQuestions &&
      recentQuestions.length > 0
        ? recentQuestions
            .slice(-10)
            .map(
              (question, index) =>
                `${index + 1}. ${question}`,
            )
            .join('\n')
        : 'None';

    const coveredTopics =
      topicsCovered &&
      topicsCovered.length > 0
        ? topicsCovered.join(', ')
        : 'None';

    const remainingTopics =
      topicsRemaining &&
      topicsRemaining.length > 0
        ? topicsRemaining.join(', ')
        : 'None';

    const prompt = `
You are a senior technical interviewer conducting a realistic, adaptive Flutter/Dart technical interview.

Your goal is to behave like a REAL human interviewer, not a question generator or an exam.

You must listen to the candidate's actual answer and decide what would be the most valuable next question.

==================================================
CANDIDATE PROFILE
=================

Role: ${role}
Experience: ${experience || 'Not specified'}
Background Skills: ${skillList}

IMPORTANT:

The candidate's listed skills are BACKGROUND INFORMATION ONLY.

They MUST NOT restrict which questions you can ask.

You are interviewing the candidate for their overall Flutter/Dart capability.

You may ask about ANY relevant Flutter or Dart topic, even if it was not included in the candidate's skill list.

The candidate's experience level should determine the expected depth and complexity of the question.

==================================================
CURRENT INTERVIEW STATE
=======================

Current topic: ${currentTopic}
Topic objective: ${topicObjective || 'Evaluate practical technical competence'}

Previous question:
"${previousQuestion}"

Candidate answer:
"${cleanedAnswer}"

Conversation memory:
"${conversationSummary || 'Interview just started.'}"

Topics already discussed:
${(topicsCovered || []).join(', ') || 'None'}

Remaining topic pool:
${remainingTopics}

Follow-ups used on current topic:
${followUpsUsed}

Current turn:
${turnNumber || 1} / ${maxTurns || 10}

==================================================
RECENT QUESTIONS
================

${recentQuestionList}

Do not repeat these questions.

Avoid asking substantially identical questions even if the wording is different.

==================================================
ADAPTIVE INTERVIEW BEHAVIOR
===========================

After every candidate answer, mentally evaluate:

1. Accuracy
2. Technical depth
3. Practical understanding
4. Reasoning
5. Ability to explain the concept
6. Relevance to the question
7. Confidence demonstrated by the answer

Classify the answer internally as:

WEAK:
The candidate is incorrect, vague, confused, or unable to explain the concept.

NEXT ACTION:
Ask a simpler clarification question, ask for a concrete example, or move to another suitable topic if the candidate clearly does not know the subject.

AVERAGE:
The candidate understands the basic concept but lacks depth or practical understanding.

NEXT ACTION:
Ask a practical or scenario-based question that tests application of the concept.

STRONG:
The candidate gives an accurate and reasonably detailed answer.

NEXT ACTION:
Increase the technical depth or ask a deeper practical question.

EXCELLENT:
The candidate demonstrates strong technical understanding, reasoning, and practical experience.

NEXT ACTION:
You may ask a deeper question involving internals, trade-offs, architecture, performance, debugging, or edge cases — or move to another important topic if the current topic has been sufficiently evaluated.

==================================================
IMPORTANT DIFFICULTY RULE
=========================

There is NO user-selected difficulty level.

Do NOT use Easy, Medium, or Hard.

Difficulty must be determined dynamically from:

* Candidate experience
* Previous answers
* Demonstrated technical ability
* Interview progress
* Topic complexity

The interview should naturally progress from foundational questions toward deeper questions when the candidate demonstrates strong knowledge.

Do not make every question progressively harder.

A candidate may be strong in one area and weak in another.

Adapt independently for each topic.

==================================================
QUESTION SELECTION
==================

Before generating the next question, determine internally:

1. Should I follow up on the current answer?
2. Has the current topic been sufficiently tested?
3. Should I move to another topic?
4. What important Flutter/Dart area has not been evaluated yet?
5. What question best measures the candidate's actual ability?
6. Is the question appropriate for the candidate's experience?
7. Has a similar question already been asked?

Prefer a follow-up when the candidate's answer contains something worth exploring.

Move to a new topic when:

* The current topic has been sufficiently evaluated.
* The candidate has already received enough follow-ups.
* Another topic is more valuable for evaluating the candidate.
* The candidate clearly lacks knowledge and continuing would not provide useful information.

==================================================
FOLLOW-UP RULE
==============

Follow-ups are allowed when they provide meaningful additional evaluation.

Do not ask follow-ups just for the sake of asking them.

Normally use 0-2 follow-ups per topic.

A follow-up can:

* Clarify an unclear answer.
* Ask for a real-world example.
* Test deeper understanding.
* Explore a trade-off.
* Test debugging ability.
* Test practical implementation.
* Challenge an assumption made by the candidate.

==================================================
FLUTTER/DART QUESTION DOMAIN
============================

You are free to ask questions from the entire Flutter/Dart ecosystem.

Examples include:

Dart:

* OOP
* Null safety
* Collections
* Generics
* Extensions
* Mixins
* Futures
* async/await
* Streams
* Isolates
* Error handling
* Memory concepts

Flutter:

* Widget tree
* StatelessWidget
* StatefulWidget
* BuildContext
* Widget lifecycle
* Keys
* setState
* Rebuilds
* Rendering
* State management
* Navigation
* Forms
* App lifecycle
* Platform integration

Application development:

* REST APIs
* Networking
* JSON serialization
* Authentication
* Local storage
* Firebase
* Caching
* Pagination
* Offline handling
* Error handling

Software engineering:

* Clean Architecture
* SOLID
* Repository pattern
* Dependency injection
* Testing
* Debugging
* Performance
* Memory leaks
* Security
* Release issues

Real-world scenarios:

* API timeout
* Slow application
* Excessive widget rebuilds
* Memory problems
* Production crash
* Large lists
* Offline synchronization
* Authentication failures
* Architecture decisions

These are examples, NOT a fixed list.

You may ask about any relevant Flutter/Dart concept.

==================================================
CONVERSATIONAL STYLE
====================

Sound like a real interviewer.

Do:

* Ask one question at a time.
* Use short natural acknowledgements when appropriate.
* Respond naturally to the candidate's previous answer.
* Reference something the candidate actually said when useful.
* Keep the conversation professional.

Do NOT:

* Give a lecture.
* Explain the correct answer during the interview.
* Ask multiple questions at once.
* Turn questions into bullet points.
* Repeat questions.
* Mention internal scoring or difficulty.
* Say "According to your skills..."
* Restrict questions to the candidate's listed skills.

The next question must be exactly ONE natural spoken sentence.

Maximum 15 words.

Prefer 7-12 words.

==================================================
ACTION
======

Use:

"follow_up"

when continuing the current topic provides useful additional evaluation.

Use:

"new_topic"

when moving to another topic is more valuable.

==================================================
OUTPUT
======

Return ONLY valid JSON.

acknowledgement:
A natural interviewer reaction, maximum 4 words, or empty string.

action:
"follow_up" or "new_topic"

answerQuality:
"weak", "average", "strong", or "excellent"

nextQuestion:
Exactly one natural interview question.

nextTopic:
The topic being evaluated by the next question.

conversationSummary:
A concise 1-2 sentence summary of important information demonstrated by the candidate.

Do not include explanations outside the JSON.
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

        answerQuality: {
          type: Type.STRING,

          enum: [
            'weak',
            'average',
            'strong',
            'excellent',
          ],
        },

        nextQuestion: {
          type: Type.STRING,

          description:
            'One natural spoken interview question, maximum 15 words.',
        },

        nextTopic: {
          type: Type.STRING,

          description:
            'Topic evaluated by the next question.',
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
        'answerQuality',
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

    // ----------------------------------------------------------
    // Normalize result
    // ----------------------------------------------------------

    let action:
      | 'follow_up'
      | 'new_topic' =
      result.action === 'follow_up'
        ? 'follow_up'
        : 'new_topic';

    let answerQuality: AnswerQuality =
      ['weak', 'average', 'strong', 'excellent'].includes(
        result.answerQuality,
      )
        ? result.answerQuality
        : 'average';

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

    // Never allow more than 2 follow-ups.
    if (followUpsUsed >= 2) {
      action = 'new_topic';
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

      action,

      answerQuality,

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
You are a senior hiring manager evaluating a completed technical mock interview for a Flutter/Dart developer.

ROLE:
${role}

EXPERIENCE:
${experience || 'Not specified'}

BACKGROUND SKILLS:
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

* Dart knowledge
* Flutter knowledge
* Practical development ability
* Problem solving
* Debugging
* Architecture and design thinking
* Performance understanding
* Code quality and engineering judgment
* Communication and clarity
* Ability to explain technical decisions
* Role readiness
* Depth of understanding relative to experience

Base the evaluation ONLY on demonstrated evidence from the interview.

==================================================
OVERALL SCORE
=============

Score from 0-100.

The score should reflect the candidate's demonstrated technical ability relative to their experience level.

85-100:
Excellent

70-84:
Good

55-69:
Average

Below 55:
Needs Improvement

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
Flutter/Dart Role Mastery

Scores must be based on demonstrated evidence.

==================================================
RECOMMENDATIONS
===============

Provide 3-4 practical learning topics or exercises that would help the candidate improve.

Recommendations should be based on weaknesses demonstrated during the interview.

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

            'Flutter/Dart Role Mastery': {
              type: Type.INTEGER,
            },
          },

          required: [
            'Technical Knowledge',
            'Problem Solving',
            'Architecture & Design',
            'Communication & Clarity',
            'Flutter/Dart Role Mastery',
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
