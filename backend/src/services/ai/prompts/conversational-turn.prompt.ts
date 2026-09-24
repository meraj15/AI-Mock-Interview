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
    previousQuestions,
    previouslyCoveredTopics,
  } = params;

  const cleanedAnswer = candidateAnswer?.trim() || 'The candidate gave little or no response.';
  const answerWordCount = cleanedAnswer.split(/\s+/).length;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList =
    cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills listed';

  // ── Questions already asked ──────────────────────────────────────────────
  const currentQuestions = (
    params.currentSessionQuestions ||
    recentQuestions ||
    []
  ).filter(Boolean);
  const currentQuestionsList =
    currentQuestions.length > 0
      ? currentQuestions.map((q, i) => `${i + 1}. ${q}`).join('\n')
      : 'None yet';

  const historicalQuestions = (previousQuestions || []).slice(0, 5).filter(Boolean);
  const historicalQuestionsBlock =
    historicalQuestions.length > 0
      ? `\nPREVIOUS SESSIONS (avoid repeating):\n${historicalQuestions.map((q) => `- ${q}`).join('\n')}`
      : '';

  const exploredList =
    areasExplored && areasExplored.length > 0 ? areasExplored.join(', ') : 'None yet';

  const pastTopicsBlock =
    previouslyCoveredTopics && previouslyCoveredTopics.length > 0
      ? `\nPrevious sessions covered: ${previouslyCoveredTopics.slice(0, 8).join(', ')}`
      : '';

  // ── Experience level calibration ─────────────────────────────────────────
  const expText = (experience || '').toLowerCase();
  const isFresher =
    expText.includes('0') ||
    expText.includes('fresher') ||
    expText.includes('intern') ||
    expText.includes('junior') ||
    expText.includes('entry');
  const isSenior =
    expText.includes('senior') ||
    expText.includes('lead') ||
    expText.includes('principal') ||
    expText.includes('architect') ||
    expText.includes('manager');

  const experienceCalibration = isFresher
    ? `The candidate is a fresher/junior. Keep questions grounded — avoid advanced system design or deep architecture questions. Focus on fundamentals, learning mindset, and basic practical experience.`
    : isSenior
      ? `The candidate is senior/experienced. Push for depth — trade-offs, edge cases, architecture decisions, team/leadership situations, and lessons learned from real failures.`
      : `Mid-level candidate. Balance practical hands-on questions with some conceptual depth. Ask for real examples.`;

  // ── Answer quality signals ───────────────────────────────────────────────
  const answerSignals: string[] = [];

  if (cleanedAnswer === 'The candidate gave little or no response.') {
    answerSignals.push('NO_RESPONSE: Candidate gave no answer.');
  } else if (answerWordCount < 12) {
    answerSignals.push('TOO_SHORT: Answer is very brief — likely vague or incomplete.');
  } else if (answerWordCount > 300) {
    answerSignals.push('TOO_LONG: Answer is very long — candidate may be rambling.');
  }

  const isGeneric =
    /good team player|hard worker|quick learner|work well under pressure|passionate about|love to (learn|code|work)/i.test(
      cleanedAnswer,
    );
  if (isGeneric) {
    answerSignals.push('GENERIC: Answer sounds clichéd or rehearsed — no concrete specifics.');
  }

  const hasSpecifics =
    /\b(specifically|for example|in my (last|previous|current)|we had a situation|at my (last|previous|current)|one time|i remember|the project was|it was a case where)\b/i.test(
      cleanedAnswer,
    );
  if (hasSpecifics) {
    answerSignals.push('HAS_SPECIFICS: Candidate gave concrete details — good signal.');
  }

  const answerSignalBlock =
    answerSignals.length > 0
      ? `\nANSWER SIGNALS:\n${answerSignals.map((s) => `- ${s}`).join('\n')}`
      : '';

  // ── Turn stage ───────────────────────────────────────────────────────────
  const currentTurn = turnNumber || 1;
  const totalMaxTurns = maxTurns || 8;
  const isIntroTransition = currentTurn === 1;
  const isPenultimateTurn = currentTurn === totalMaxTurns - 1;
  const isFinalClosingTurn = currentTurn >= totalMaxTurns;

  let stageTag: string;
  let stageInstruction: string;
  let acknowledgementGuidance: string;

  if (isFinalClosingTurn) {
    stageTag = 'CLOSING';
    stageInstruction = `The interview is done. action MUST be "end_interview". 
Write a warm, genuine closing — thank them naturally, like a real interviewer would wrap up a conversation. 
nextQuestion is actually your closing line, NOT a question. nextTopic: "Interview Conclusion".`;
    acknowledgementGuidance = `Something like "That's really helpful, thank you" or "Great, I appreciate you sharing that."`;
  } else if (isPenultimateTurn) {
    stageTag = 'WRAPPING_UP';
    stageInstruction = `This is your last technical question. 
Naturally signal you're wrapping up — something like "Last one from me..." or "One final thing I wanted to ask...". 
One question mark, max 18 words. Pick the most important unexplored area still worth covering for this role.`;
    acknowledgementGuidance = `Warm, acknowledging — like you're genuinely satisfied with the conversation so far.`;
  } else if (isIntroTransition) {
    stageTag = 'FIRST_TECHNICAL';
    stageInstruction = `The candidate just introduced themselves. Now transition naturally into the first real question.
Pick ONE specific thing they mentioned (a tool, a project, a company, an experience) and build your first question from it.
If they didn't mention anything specific, pick the most relevant starting point for a ${role}.
DO NOT ask a generic "tell me about your experience" question — that was the opener. Get specific now.
Max 18 words. One question mark.`;
    acknowledgementGuidance = `React to something specific they said — "Oh nice, you've worked with X..." or "Interesting background, so..."`;
  } else {
    stageTag = 'CORE';
    stageInstruction = `You are mid-interview. Choose the most natural next move based on their last answer:

DECISION FLOW (think like a real interviewer):
→ Was the answer strong and specific? 
   → GO DEEPER: dig into edge cases, trade-offs, what went wrong, what they'd do differently
→ Was the answer vague, generic, or too short?
   → CHALLENGE: ask for a concrete example, a specific situation, or push for more detail
→ Did they mention something interesting you want to explore?
   → DEEP DIVE: follow that thread before moving on
→ Did they say something that connects to something from earlier?
   → CONNECT: reference it naturally ("You mentioned X earlier — how does that relate to...")
→ Are you satisfied with this topic and ready to move on?
   → TRANSITION: shift naturally to the next most important unexplored area

Pick the action that a real human interviewer would choose in this moment.
Max 18 words. Exactly one question mark. No compound questions (no "and" joining two questions).`;
    acknowledgementGuidance = `Match the action:
- DEEP DIVE / CHALLENGE: "Okay, give me a specific example of that —" / "Interesting — but what exactly did YOU do there?" / "Right, so what happened when it broke?"
- CONNECT: "Actually — you mentioned [X] earlier, and this ties into that..." 
- TRANSITION: "Got it." / "Makes sense." / "Alright, let's shift gears a bit."
- If answer was NO_RESPONSE or very short: "That's okay, take a moment — " or "No worries, let me rephrase that."
Keep it natural. 2–8 words. Varies every turn — never repeat the same acknowledgement twice.`;
  }

  // ── Memory block ─────────────────────────────────────────────────────────
  // Always include summary if we have one — even early turns benefit from it
  const memoryBlock =
    conversationSummary &&
    conversationSummary.trim() &&
    conversationSummary !== 'Interview in progress.'
      ? `\nINTERVIEW MEMORY (what you know so far):\n${conversationSummary.trim()}`
      : currentTurn > 1
        ? `\nINTERVIEW MEMORY: Interview just started, no patterns established yet.`
        : '';

  const prompt = `You are Alex, a senior hiring manager with 10 years of interviewing experience across many industries.

YOUR PERSONALITY AS AN INTERVIEWER:
- You are genuinely curious about candidates — not going through a checklist
- You listen carefully and react to what they actually said, not what you expected them to say
- You follow interesting threads naturally before moving on
- You challenge vague answers with warmth, not aggression ("give me a real example" not "that's wrong")
- You reference things candidates said earlier — it shows you're paying attention
- You use natural spoken transitions: "Alright, shifting gears...", "That's interesting, actually...", "Let me ask you something different..."
- You NEVER ask two similar questions back to back
- You NEVER sound like a form or a checklist

==================================================
CANDIDATE PROFILE
==================================================
Role: ${role}
Experience: ${experience || 'Not specified'}
Background Skills (context only): ${skillList}

CALIBRATION: ${experienceCalibration}

==================================================
CURRENT INTERVIEW STATE
==================================================
Turn: ${currentTurn} of ${totalMaxTurns}
Stage: ${stageTag}
Follow-ups used so far: ${followUpsUsed ?? 0}

YOUR LAST QUESTION:
"${previousQuestion}"

CANDIDATE'S ANSWER:
"${cleanedAnswer}"
(word count: ~${answerWordCount} words)
${answerSignalBlock}
${memoryBlock}

AREAS ALREADY EXPLORED THIS SESSION: ${exploredList}${pastTopicsBlock}

QUESTIONS ALREADY ASKED — DO NOT REPEAT OR CLOSELY PARAPHRASE:
${currentQuestionsList}${historicalQuestionsBlock}

==================================================
YOUR DECISION FOR THIS TURN
==================================================
Stage instruction:
${stageInstruction}

Acknowledgement guidance:
${acknowledgementGuidance}

==================================================
OUTPUT RULES
==================================================
1. nextQuestion: Exactly ONE question mark. Max 18 words. No compound questions ("X and Y?"). 
   Sound like something a real person would say in conversation, not read off a page.
2. acknowledgement: 2–8 natural spoken words. Must match the action you chose. Vary it every turn.
3. action: "follow_up" | "new_topic" | "end_interview"
   - follow_up: staying on same topic (challenge, deep dive, or connect)
   - new_topic: transitioning to a fresh area
   - end_interview: ONLY on final closing turn
4. nextTopic: The evaluation area this question targets (e.g. "Problem Solving", "System Design", 
   "Leadership", "Communication"). Pick what genuinely fits this role — not a predefined list.
5. conversationSummary: Update the running interview memory. MAX 40 words.
   Format: "[Topic]: [one-line signal (strength/gap/interesting)]" per topic covered.
   Always compress — never expand. This memory helps you reference earlier answers naturally.

Return ONLY valid JSON matching the schema.`;

  return { prompt, stageTag, cleanedAnswer, currentTurn, totalMaxTurns };
}