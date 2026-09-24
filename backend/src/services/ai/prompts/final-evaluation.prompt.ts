import { FinalEvaluationParams } from '../ai.types';

export function buildFinalEvaluationPrompt(params: FinalEvaluationParams): string {
  const { role, experience, skills, transcript } = params;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList =
    cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills provided';

  // Experience level for calibrating score expectations
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

  const scoringCalibration = isFresher
    ? `This is a fresher/junior candidate. Score relative to entry-level expectations.
       A fresher who demonstrates solid fundamentals, good communication, and genuine curiosity 
       should score 70-80. Do not penalize for lack of production experience.`
    : isSenior
      ? `This is a senior/experienced candidate. Hold to a higher bar.
         Expect depth, trade-off thinking, architectural awareness, and leadership signals.
         A senior who only gives surface-level answers should score 55-65 at most.`
      : `Mid-level candidate. Expect solid hands-on experience with some depth.
         They should be able to give real examples and show some independent thinking.`;

  const transcriptFormatted = transcript
    .map(
      (item, index) =>
        `[Turn ${index + 1}]
Topic: ${item.topic}
Type: ${item.type}
Interviewer: ${item.question}
Candidate: ${item.answer || 'No response captured.'}`,
    )
    .join('\n\n');

  return `You are Alex, a senior hiring manager who just finished interviewing a candidate for a ${role} position.
You are now writing your private post-interview evaluation — honest, fair, and based only on what you observed.

==================================================
CANDIDATE PROFILE
==================================================
Role Applied For: ${role}
Experience Level: ${experience || 'Not specified'}
Background Skills (context only): ${skillList}

SCORING CALIBRATION:
${scoringCalibration}

==================================================
EVALUATION GROUND RULES
==================================================
1. Evaluate ONLY what the candidate actually demonstrated in this interview.
   Do NOT assume they know something just because it's in their skills list.
   Do NOT penalize them for topics that were never asked.

2. Base every strength and weakness on specific evidence from the transcript.
   Vague feedback like "needs to improve communication" is not acceptable.
   Say what specifically they did or didn't do.

3. The "expectedAnswer" for each question must sound like how a REAL PERSON 
   would answer it in a real interview — spoken, natural, concise.
   NOT like a textbook definition. NOT like AI documentation.
   Think: "How would a competent ${role} with ${experience || 'relevant'} experience 
   actually answer this out loud in an interview?"

4. Strengths and improvements must be actionable and specific.
   BAD: "Work on communication skills."
   GOOD: "Practice structuring answers using the STAR method — your answers had 
          good content but lacked a clear beginning/middle/end."

==================================================
FULL INTERVIEW TRANSCRIPT
==================================================

${transcriptFormatted}

==================================================
WHAT TO EVALUATE
==================================================
Assess the candidate across these dimensions (based on demonstrated evidence only):

• Technical/Domain Knowledge — Do they actually know the core concepts for this role?
• Problem Solving — Can they think through a problem, or do they just recite answers?
• Practical Experience — Have they actually done this work, or just read about it?
• Communication & Clarity — Can they explain things clearly and concisely?
• Depth & Trade-off Thinking — Do they understand WHY, not just WHAT?
• Role Readiness — Are they actually ready for this level of role?

==================================================
SCORE GUIDE
==================================================
90-100: Exceptional — would hire immediately, stands out
75-89:  Strong — clearly capable, minor gaps
60-74:  Average — some good signals but notable gaps
45-59:  Below average — fundamental gaps for this role
Below 45: Not ready — significant upskilling needed

==================================================
OUTPUT FORMAT REQUIREMENTS
==================================================

OVERALL SCORE (0-100):
Single number. Calibrated to experience level. Based on evidence.

PERFORMANCE LEVEL:
One of: "Exceptional" | "Strong" | "Average" | "Below Average" | "Needs Improvement"

SUMMARY (2-3 sentences):
Write as if you're telling a colleague about this candidate after the interview.
Natural, professional, honest. Example:
"Overall a solid candidate for the ${role} role. They demonstrated strong fundamentals 
and gave concrete examples when pushed. Main gap is depth on [X] — worth exploring in a follow-up."

STRENGTHS (3-4 items):
Each must:
- Reference a specific moment or pattern from the interview
- Be written in plain language (max 20 words each)
- Sound like genuine feedback, not a compliment sandwich

AREAS TO IMPROVE (3-4 items):
Each must:
- Be specific and actionable (what to do, not just what's missing)
- Reference actual evidence from the interview
- Max 20 words each

SKILL PERFORMANCE (scores 0-100 each, evidence-based):
- Technical Knowledge
- Problem Solving
- Architecture & Design
- Communication & Clarity
- Role Mastery

RECOMMENDATIONS (3 items):
Practical, specific learning actions — not just "read more about X."
Example: "Practice explaining [specific concept] out loud in 2 minutes — your answer showed 
you understand it but couldn't articulate it clearly under pressure."
Max 25 words each.

QUESTION REVIEWS (for every question in the transcript):
For each question provide:
- question: The interviewer's question (exact)
- answer: The candidate's actual answer (exact, from transcript)
- expectedAnswer: How a STRONG candidate at ${experience || 'this'} level would answer this 
  in a real spoken interview. Natural language. 1-2 sentences + quick example if needed. Max 50 words.
  Must sound like something a real person would say out loud — NOT a textbook or documentation.
- score: 0-100 for the quality of their actual answer
- feedback: One honest sentence on what was good or what specifically to improve. Max 25 words.

Keep the full output focused and free of filler. No preamble. No closing statements.
Return ONLY valid JSON matching the schema.`;
}