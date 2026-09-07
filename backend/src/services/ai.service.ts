
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
  action: 'follow_up' | 'new_topic' | 'end_interview';
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
  'gemini-3.6-flash',
  'gemini-3.8-flash',
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
You are a senior technical interviewer welcoming a candidate to a live, realistic technical interview.

CANDIDATE TARGET ROLE: ${role.trim()}
EXPERIENCE LEVEL: ${experienceText}
PROGRAMMING LANGUAGES & FRAMEWORKS: ${skillList}

STAGE 1 / TURN 1 OPENING QUESTION:
In every real human interview, the opening turn MUST ALWAYS be a warm, role-tailored introduction question welcoming the candidate and asking for their background based on their target role.

Generate exactly ONE natural opening question:
1. Welcome the candidate warmly.
2. Ask them to introduce themselves and give an overview of their background specifically as a ${role.trim()}.

Examples:
* "Welcome! To start us off today, could you introduce yourself and walk me through your background as a ${role.trim()}?"
* "Hi, welcome! Could you please introduce yourself and share an overview of your background as a ${role.trim()}?"
* "Welcome to the interview! To begin, could you introduce yourself and your journey in ${role.trim()}?"

CRITICAL REQUIREMENTS:
* Warm and collegial greeting.
* Ask for their background specifically tailored to their role "${role.trim()}".
* Do NOT ask technical questions, coding problems, or trivia in this opening turn.
* Strictly ONE question mark. Maximum 18 words.

Return ONLY valid JSON.
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        firstQuestion: {
          type: Type.STRING,
          description:
            'A warm opening question welcoming the candidate and asking for their background as a ' +
            role.trim() +
            '. Maximum 18 words. Exactly one question mark.',
        },
      },

      required: ['firstQuestion'],

      additionalProperties: false,
    };

    console.log(
      `[AIService] Generating first question for role "${role.trim()}"...`,
    );

    const result =
      await this.executeWithFallback(
        prompt,
        schema,
      );

    const defaultFirstQ = `Welcome! Could you please introduce yourself and share an overview of your background as a ${role.trim()}?`;
    const firstQuestion = this.enforceSingleQuestion(
      String(result.firstQuestion || '').trim(),
      defaultFirstQ,
    );

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

    const currentTurn = turnNumber || 1;
    const totalMaxTurns = maxTurns || 8;
    const isIntroTransition = currentTurn === 1;
    const isPenultimateTurn = currentTurn === totalMaxTurns - 1;
    const isFinalClosingTurn = currentTurn >= totalMaxTurns;

    let stageInstructions = '';
    if (isFinalClosingTurn) {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [FINAL_CLOSING_FAREWELL]
==================================================
* The candidate has just answered the final technical question.
* The interview has officially CONCLUDED.
* Do NOT ask another technical question or coding problem!
* Action MUST be: "end_interview"
* nextTopic: "Interview Conclusion"
* nextQuestion: Deliver a warm, authentic, collegial closing farewell remark thanking the candidate for their time and thoughtful answers, and wishing them luck.
  Example nextQuestion: "That brings us to the end of our interview today! Thank you so much for walking through your experience with me. We'll compile your performance review right now. Best of luck!"
* acknowledgement: A warm spoken reaction (e.g. "Thank you for walking me through that." or "Understood, thank you.").
`;
    } else if (isPenultimateTurn) {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [PENULTIMATE_WRAPUP_QUESTION]
==================================================
* We have time for ONE last technical question before wrapping up today.
* Signpost the finish naturally to the candidate in your question:
  Example: "We have time for one last question before we wrap up today: what's a challenging bug or performance issue you recently diagnosed and resolved?"
  Example: "For our final technical question today, what's one architectural decision you'd make differently on a past project?"
* Exactly ONE question mark. Maximum 18 words.
`;
    } else if (isIntroTransition) {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [TRANSITION_FROM_INTRO_TO_TECHNICAL]
==================================================
* The candidate has just provided their background introduction.
* A real human interviewer ACTIVELY LISTENS to their introduction!
* Identify ONE specific programming language or framework the candidate mentioned or listed in their profile (${skillList || role}).
* CRITICAL RULE - SKILLS ARE LANGUAGES OR FRAMEWORKS, NOT CONCEPTS:
  By "skill", we strictly mean the candidate's PROGRAMMING LANGUAGES OR FRAMEWORKS (such as Dart, Flutter, React, TypeScript, etc.).
  DO NOT ask questions about abstract theoretical concepts (such as Clean Architecture definitions, SOLID principles, or OOP textbook theory).
* Ask ONE direct, practical technical question grounded specifically in how they use that programming language or framework:
  Example if Flutter/Dart: "You mentioned working with Flutter and Dart. How did you handle state management across your screens?"
  Example if Flutter/Dart: "Since you build with Flutter, how do you handle asynchronous streams and API errors in Dart?"
  Example if Flutter: "In your Flutter apps, what approach did you use for caching network responses offline?"
  Example: "In Dart, how do you optimize widget rebuilds when rendering dynamic scrollable lists?"
* If their intro was very brief or did not name a specific tool:
  Example: "Great to have you! To kick off the technical side, how do you manage state and navigation in ${role.includes('Flutter') ? 'Flutter' : role}?"
* Human acknowledgement: short, realistic conversational reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). Spoken via TTS only, never displayed in UI card.
* Strictly ONE question mark. Maximum 18 words.
`;
    } else {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [CORE_TECHNICAL_EXPLORATION]
==================================================
* Evaluate practical competence in the candidate's programming languages and frameworks (${skillList || role}).
* CRITICAL RULE - SKILLS ARE LANGUAGES OR FRAMEWORKS, NOT CONCEPTS:
  Skills mean strictly their PROGRAMMING LANGUAGES AND FRAMEWORKS (e.g. Dart, Flutter).
  DO NOT ask questions about abstract theoretical concepts (like SOLID principles, OOP definitions, or design pattern theory).
* Every question MUST be a practical question grounded in their actual language or framework:
  - Framework APIs & features (e.g. Flutter state management, widget lifecycles, navigation, rendering)
  - Language features (e.g. Dart null safety, async/await, isolates, streams, records, collections)
  - Real-world engineering: API error handling, offline caching, memory leaks, and UI performance in their language/framework.
* If candidate's previous answer was strong: ask ONE deeper follow-up on performance, trade-offs, or edge cases in that language/framework.
* If candidate's previous answer was weak: gently acknowledge and smoothly pivot to another practical feature in their language/framework.
* Human acknowledgement: short, realistic conversational reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). Spoken via TTS only, never displayed in UI card.
* Strictly ONE question mark. Maximum 18 words.
`;
    }

    const prompt = `
You are a senior technical interviewer conducting a live, adaptive technical interview for a ${role}.

Your goal is to behave like a REAL human interviewer, not an automated quiz bot or an exam.

Listen carefully to the candidate's actual answer and decide what would be the most valuable next question.

==================================================
CANDIDATE PROFILE
=================
Role: ${role}
Experience: ${experience || 'Not specified'}
Languages & Frameworks: ${skillList}

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
${currentTurn} / ${totalMaxTurns}

${stageInstructions}

==================================================
RECENT QUESTIONS ALREADY ASKED
==============================
${recentQuestionList}

Do not repeat these questions. Avoid asking substantially identical questions.

==================================================
CRITICAL HUMAN INTERVIEW RULES
==============================
1. STRICTLY ONE QUESTION: Exactly ONE question mark ('?'). NEVER ask two questions in one sentence (no "and how...", "and why...", "and what...").
2. CONCISE & PUNCHY: Spoken questions must be between 8 and 18 words. Never ask a long paragraph or bullet points.
3. SPOKEN ACKNOWLEDGEMENT ONLY: Provide a short, realistic conversational reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). This is spoken via TTS only and MUST NOT be part of nextQuestion.
4. SKILLS ARE LANGUAGES & FRAMEWORKS, NOT CONCEPTS: Ask practical questions about actual programming languages and frameworks (e.g. Dart, Flutter). Never ask abstract dictionary definitions, OOP theory, or textbook concept quizzes.
5. NATURAL CONVERSATIONAL TONE: Sound like a friendly senior technical colleague speaking over video call.

==================================================
OUTPUT FORMAT
=============
Return ONLY valid JSON.

acknowledgement:
Short, realistic conversational reaction to what the candidate just said (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point.", "Thank you."). Spoken via TTS only; do NOT include the question here.

action:
"follow_up", "new_topic", or "end_interview"

answerQuality:
"weak", "average", "strong", or "excellent"

nextQuestion:
The pure technical question ONLY (or warm closing remark if end_interview). Do NOT include any acknowledgement, reaction, or conversational filler in nextQuestion. Maximum 18 words. Exactly one question mark.

nextTopic:
The language or framework topic being evaluated (e.g. "Flutter State Management", "Dart Async Programming", or "Interview Conclusion").

conversationSummary:
A concise 1-2 sentence summary of technical ability demonstrated so far.
`;

    const schema = {
      type: Type.OBJECT,

      properties: {
        acknowledgement: {
          type: Type.STRING,
          description:
            'Short natural interviewer reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). Spoken via TTS only, never shown in UI.',
        },

        action: {
          type: Type.STRING,
          enum: [
            'follow_up',
            'new_topic',
            'end_interview',
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
            'The pure technical question ONLY (or closing remark if end_interview). Do NOT include the acknowledgement or conversational filler here. Grounded in the candidate\'s programming languages or frameworks. Maximum 18 words. Exactly one question mark.',
        },

        nextTopic: {
          type: Type.STRING,
          description:
            'The technical area or language/framework feature being evaluated (e.g. "Flutter State Management", "Dart Async Programming", or "Interview Conclusion").',
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
      | 'new_topic'
      | 'end_interview' =
      result.action === 'end_interview' || isFinalClosingTurn
        ? 'end_interview'
        : result.action === 'follow_up'
        ? 'follow_up'
        : 'new_topic';

    let answerQuality: AnswerQuality =
      ['weak', 'average', 'strong', 'excellent'].includes(
        result.answerQuality,
      )
        ? result.answerQuality
        : 'average';

    const primaryTool =
      skills && skills.length > 0
        ? skills[0]
        : role.includes('Flutter')
        ? 'Flutter'
        : role;

    const fallbackQuestion = isFinalClosingTurn
      ? 'That brings us to the end of our interview today! Thank you so much for walking through your experience with me.'
      : isPenultimateTurn
      ? `For our final question today, what's a challenging bug you recently diagnosed and resolved in ${primaryTool}?`
      : isIntroTransition
      ? `To start on technicals, how do you manage state and async operations in ${primaryTool}?`
      : `In ${primaryTool}, how do you structure your code to avoid unnecessary UI rebuilds?`;

    let nextQuestion = this.enforceSingleQuestion(
      String(result.nextQuestion || '').trim(),
      fallbackQuestion,
    );

    let nextTopic =
      String(
        result.nextTopic ||
          (isFinalClosingTurn ? 'Interview Conclusion' : currentTopic),
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
    if (followUpsUsed >= 2 && action === 'follow_up') {
      action = 'new_topic';
    }

    if (!nextQuestion) {
      nextQuestion = fallbackQuestion;
    }

    if (!nextTopic) {
      nextTopic = isFinalClosingTurn ? 'Interview Conclusion' : currentTopic;
    }

    return {
      acknowledgement,
      action,
      answerQuality,
      nextQuestion,
      nextTopic,
      conversationSummary: summary,
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
