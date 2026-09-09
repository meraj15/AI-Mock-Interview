import { ConversationalTurnParams } from '../ai.types';

export function buildConversationalTurnPrompt(params: ConversationalTurnParams): {
  prompt: string;
  stageTag: string;
  cleanedAnswer: string;
  currentTurn: number;
  totalMaxTurns: number;
} {
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
  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList = cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills provided';

  const recentQuestionList =
    recentQuestions && recentQuestions.length > 0
      ? recentQuestions.slice(-5).map((q, i) => `${i + 1}. ${q}`).join('\n')
      : 'None';

  const exploredList = areasExplored && areasExplored.length > 0 ? areasExplored.join(', ') : 'None yet';

  const currentTurn = turnNumber || 1;
  const totalMaxTurns = maxTurns || 8;
  const isIntroTransition = currentTurn === 1;
  const isPenultimateTurn = currentTurn === totalMaxTurns - 1;
  const isFinalClosingTurn = currentTurn >= totalMaxTurns;

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

Return ONLY valid JSON matching the schema.`;

  return { prompt, stageTag, cleanedAnswer, currentTurn, totalMaxTurns };
}
