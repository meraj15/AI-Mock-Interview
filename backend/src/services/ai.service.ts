
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
            '[AIService] Temporary error encountered. Waiting 1s before fallback model...',
          );
          await new Promise((r) => setTimeout(r, 1000));
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
You are a senior hiring manager and technical interviewer planning a realistic, comprehensive interview for a ${role.trim()}.

CANDIDATE TARGET ROLE: ${role.trim()}
EXPERIENCE LEVEL: ${experience?.trim() || 'Not specified'}
BACKGROUND SKILLS & TOOLS: ${skillList}

TASK:
Create 5 to 7 broad evaluation topic areas tailored specifically to the real-world responsibilities, core tools, problem-solving, and day-to-day work of a ${role.trim()}.

CRITICAL ROLE-SPECIFIC GUIDELINES:
1. Ground every topic directly in the actual domain and duties of "${role.trim()}":
   - If a Support Engineer / Technical Support role: ticket diagnosis, root cause analysis, customer communication & de-escalation, system log analysis, SQL / database verification, SLA incident workflows, bug triage with engineering.
   - If a Software Engineer / Developer role: system design, architecture, practical coding in candidate's stack (${skillList}), API integration, asynchronous operations, state handling, performance, debugging.
   - If a DevOps / Cloud / SRE role: CI/CD pipelines, Docker/Kubernetes, infrastructure as code, cloud monitoring, disaster recovery, security.
   - If a QA / Automation role: test planning, automation frameworks, bug lifecycle, edge cases, regression, API testing.
   - If a Data / ML role: data pipelines, SQL, data modeling, feature engineering, data quality, model evaluation.
   - For ANY other role: produce topics that authentically evaluate the candidate's real-world competence in that specific profession.
2. The candidate's background skills (${skillList}) provide context for their specific tools and tech stack, but do NOT restrict topics to only those keywords.
3. DO NOT assume Flutter or mobile development unless the role explicitly specifies Flutter or Mobile!
4. Each topic must contain:
   - "name": Concise topic title (e.g., "Incident Triage & Root Cause Analysis", "System Log Investigation", "SQL & Data Verification")
   - "objective": Clear 1-sentence description of what competencies are being evaluated.

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
      `[AIService] Generating dynamic interview topics for role "${role.trim()}"...`,
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
                  'General Discussion',
              ).trim(),

              objective: String(
                topic?.objective ||
                  `Evaluate competence for ${role.trim()}`,
              ).trim(),
            }))
            .filter(
              (topic: InterviewTopic) =>
                topic.name.length > 0,
            )
        : [];

    console.log(
      `[AIService] Topics generated for "${role.trim()}": ${topics
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
* The candidate has just answered the final interview question.
* The interview has officially CONCLUDED.
* Do NOT ask another technical question or problem!
* Action MUST be: "end_interview"
* nextTopic: "Interview Conclusion"
* nextQuestion: Deliver a warm, authentic, collegial closing farewell remark thanking the candidate for their time and thoughtful answers, and wishing them luck in their journey as a ${role}.
  Example nextQuestion: "That brings us to the end of our interview today! Thank you so much for walking through your experience with me. We'll compile your performance review right now. Best of luck!"
* acknowledgement: A warm spoken reaction (e.g. "Thank you for walking me through that." or "Understood, thank you.").
`;
    } else if (isPenultimateTurn) {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [PENULTIMATE_WRAPUP_QUESTION]
==================================================
* We have time for ONE last question before wrapping up today.
* Signpost the finish naturally to the candidate in your question:
  Example: "We have time for one last question before we wrap up today: what's a challenging problem or incident you recently resolved as a ${role}?"
  Example: "For our final question today, what's one process or technical decision you'd approach differently on a past project?"
* Exactly ONE question mark. Maximum 18 words.
`;
    } else if (isIntroTransition) {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [TRANSITION_FROM_INTRO_TO_TECHNICAL]
==================================================
* The candidate has just provided their background introduction.
* A real human interviewer ACTIVELY LISTENS to their introduction!
* Identify ONE specific tool, technology, programming language, system, or scenario the candidate mentioned in their intro or listed in their profile for their role as a ${role} (${skillList || role}).
* CRITICAL ROLE-SPECIFIC RULE:
  Ground the technical question strictly in the candidate's actual role "${role}" and their tools:
  - If a Support Engineer / Operations role: ask about how they diagnosed a tricky customer issue, investigated server/application logs, or used SQL/tickets to resolve an escalation.
    Example: "You mentioned diagnosing customer issues using SQL. How did you track down that database discrepancy?"
    Example: "Since you handle customer escalations, how do you determine root cause when server logs show intermittent errors?"
  - If a Developer / Software Engineer role: ask about how they implemented a feature, managed state, or handled async API errors using their specific language or framework.
    Example: "You mentioned building that service with Python. How did you handle background task processing there?"
  - If a DevOps / Cloud role: ask about CI/CD pipelines, container orchestration, or cloud infrastructure troubleshooting.
  - DO NOT ask about Flutter or Dart unless the candidate's role is specifically Flutter or Dart!
* Human acknowledgement: short, realistic conversational reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). Spoken via TTS only, never displayed in UI card.
* Strictly ONE question mark. Maximum 18 words.
`;
    } else {
      stageInstructions = `
==================================================
CURRENT INTERVIEW STAGE: [CORE_TECHNICAL_EXPLORATION]
==================================================
* Evaluate practical competence in the candidate's actual role (${role}) and their tools/skills (${skillList}).
* Every question MUST be a practical question grounded in their actual role domain:
  - Real-world scenarios, troubleshooting, incident management, edge cases, system performance, or engineering judgment relevant to a ${role}.
  - If candidate is a Support Engineer: focus on ticket triage, log parsing, isolating bugs between client/backend, SQL queries, SLA prioritization, and communicating complex technical fixes.
  - If candidate is a Developer: focus on framework APIs, code architecture, error handling, optimization, and debugging in their tech stack.
  - If candidate's previous answer was strong: ask ONE deeper follow-up on edge cases, root cause, or trade-offs.
  - If candidate's previous answer was weak: gently acknowledge and smoothly pivot to another practical area of ${role}.
  - DO NOT ask about Flutter or Dart unless the role is Flutter!
* Human acknowledgement: short, realistic conversational reaction (2-4 words, e.g. "Understood.", "Got it, that makes sense.", "Makes sense.", "Fair point."). Spoken via TTS only, never displayed in UI card.
* Strictly ONE question mark. Maximum 18 words.
`;
    }

    const prompt = `
You are a senior technical interviewer conducting a live, adaptive interview for a ${role}.

Your goal is to behave like a REAL human interviewer, not an automated quiz bot or an exam.

Listen carefully to the candidate's actual answer and decide what would be the most valuable next question.

==================================================
CANDIDATE PROFILE
=================
Role: ${role}
Experience: ${experience || 'Not specified'}
Skills & Tools: ${skillList}

==================================================
CURRENT INTERVIEW STATE
=======================
Current topic: ${currentTopic}
Topic objective: ${topicObjective || `Evaluate practical competence for ${role}`}

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
4. GROUNDED IN CANDIDATE'S ROLE & TOOLS: Ask practical questions about the actual tools, systems, and responsibilities of a ${role} (using their tools: ${skillList}). Never assume Flutter or mobile development unless the role explicitly states Flutter.
5. NATURAL CONVERSATIONAL TONE: Sound like a friendly senior colleague speaking over video call.

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
The pure interview question only (or warm closing remark if end_interview). Do NOT include any acknowledgement, reaction, or conversational filler in nextQuestion. Grounded strictly in the candidate's role and tools. Maximum 18 words. Exactly one question mark.

nextTopic:
The topic or skill area being evaluated (e.g. "Incident Diagnosis", "SQL Verification", or "Interview Conclusion").

conversationSummary:
A concise 1-2 sentence summary of ability demonstrated so far.
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
            'The pure interview question ONLY (or closing remark if end_interview). Do NOT include the acknowledgement or conversational filler here. Grounded in the candidate\'s role and tools. Maximum 18 words. Exactly one question mark.',
        },

        nextTopic: {
          type: Type.STRING,
          description:
            'The topic or skill area being evaluated (or "Interview Conclusion").',
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

    const fallbackQuestion = isFinalClosingTurn
      ? 'That brings us to the end of our interview today! Thank you so much for walking through your experience with me.'
      : isPenultimateTurn
      ? `For our final question today, what's a challenging problem or complex issue you recently resolved as a ${role}?`
      : isIntroTransition
      ? `To start into your technical work, what's a primary tool or system you rely on most as a ${role}?`
      : `In your day-to-day work as a ${role}, how do you approach diagnosing and resolving unexpected issues?`;

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
