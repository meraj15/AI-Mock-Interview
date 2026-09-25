import { FinalEvaluationParams } from '../ai.types';

export function buildFinalEvaluationPrompt(params: FinalEvaluationParams): string {
  const { role, experience, skills, transcript } = params;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList =
    cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills provided';

  // ── Experience detection ─────────────────────────────────────────────────
  const expText = (experience || '').toLowerCase();
  const isFresher =
    expText.includes('0') ||
    expText.includes('fresher') ||
    expText.includes('intern') ||
    expText.includes('junior') ||
    expText.includes('entry') ||
    expText.includes('1 year') ||
    expText.includes('1year');
  const isSenior =
    expText.includes('senior') ||
    expText.includes('lead') ||
    expText.includes('principal') ||
    expText.includes('architect') ||
    expText.includes('manager');

  // ── Scoring calibration ──────────────────────────────────────────────────
  const scoringCalibration = isFresher
    ? `This is a fresher or junior candidate (${experience}).
Score them against what you would expect from someone just starting out.
What matters for a fresher:
- Do they know the basics of their field?
- Can they explain things clearly in simple words?
- Do they show curiosity and willingness to learn?
- Do they give real examples even if small (personal projects, college work, internship tasks)?
A fresher who knows their fundamentals, communicates well, and shows genuine interest
should score 70 to 80. Do NOT mark them down for not having production experience.
That is not fair — they are just starting.
A fresher who cannot answer basic questions or shows no curiosity scores below 55.`
    : isSenior
    ? `This is a senior or lead level candidate (${experience}).
Hold them to a high bar — they have years of experience and should show it.
What matters for a senior:
- Do they think in trade-offs, not just solutions?
- Can they talk about decisions they made, not just things they did?
- Do they show awareness of how their work affects the team and the system?
- Can they talk about failures and what they learned?
- Do they show any signs of leading, mentoring, or influencing others?
A senior who only gives surface level answers should score 55 to 65 at most.
A senior who shows real depth, good judgment, and leadership thinking scores 80 to 90.`
    : `This is a mid level candidate (${experience}).
They should have real hands-on experience and some depth.
What matters:
- Can they give specific real examples from their work?
- Do they show some independent thinking — not just "I followed the process"?
- Can they explain the WHY behind their decisions, not just the WHAT?
- Do they show awareness of trade-offs even if not deeply?
A mid level who gives concrete examples and shows some depth scores 65 to 80.`;

  // ── Feedback language calibration ────────────────────────────────────────
  const feedbackLanguage = isFresher
    ? `Write all feedback in encouraging and simple language.
This is someone early in their career — harsh or corporate feedback will not help them.
Be honest but kind. Focus on what they can actually do to improve.
Use simple words. Short sentences. Sound like a supportive senior colleague.`
    : isSenior
    ? `Write feedback that is direct and peer level — do not soften it too much.
Senior people can handle honest feedback and they respect it more than vague praise.
Be specific. Point to exact moments in the interview as evidence.
Sound like an honest hiring manager writing a real post-interview note.`
    : `Write feedback that is clear and practical.
Be specific and kind — not harsh but not vague either.
Sound like a good manager giving a real performance review.`;

  // ── Expected answer calibration ──────────────────────────────────────────
  const expectedAnswerRule = isFresher
    ? `expectedAnswer for fresher level:
Write how a STRONG fresher would answer this — someone who knows their basics well.
Simple words. Short and clear. Like they are speaking out loud in an interview.
Do NOT write a textbook definition. Do NOT use corporate or advanced vocabulary.
Example style: "I would start by checking the error logs to see what the message says,
then try to reproduce the issue locally. Once I can reproduce it, I look at the code
around where it breaks and add some debug logs to narrow it down."`
    : isSenior
    ? `expectedAnswer for senior level:
Write how a STRONG senior would answer this — someone with real depth and judgment.
They should mention trade-offs, real decisions, or how they think about the bigger picture.
Natural spoken English but shows experience and confidence.
Example style: "First I'd look at whether this is a data issue or a logic issue —
those need different approaches. I'd check our monitoring dashboards first to see if
there is a pattern, then dig into the specific failing cases. In my last role we had
something similar and the root cause turned out to be a race condition in our cache
invalidation logic — took us a day to find but taught us to add better observability."`
    : `expectedAnswer for mid level:
Write how a STRONG mid level candidate would answer — real experience, some depth.
Conversational but shows they have actually done this work before.
One or two concrete sentences plus a small real example. Max 50 words.`;

  const transcriptFormatted = transcript
    .map(
      (item, index) =>
        `[Turn ${index + 1}]
Topic: ${item.topic}
Interviewer: ${item.question}
Candidate: ${item.answer || 'No response given.'}`,
    )
    .join('\n\n');

  return `You are Alex, a hiring manager who just finished interviewing a candidate for the role of ${role}.
You are now writing your honest, private post-interview notes.
Write like a real person — not a report, not a document.
Simple English. Short sentences. Honest and direct.
Never use these words: utilize, leverage, demonstrate, articulate, proficiency, competency,
showcase, endeavour, facilitate. Sound like a real person, not AI.
Return ONLY valid JSON. No explanation. No markdown. No extra text.

==================================================
CANDIDATE
==================================================
Role: ${role}
Experience: ${experience || 'Not specified'}
Background skills (context only — do not assume they know these): ${skillList}

==================================================
SCORING GUIDE
==================================================
${scoringCalibration}

Score ranges:
90 to 100 — Exceptional. Would hire immediately. Stood out clearly.
75 to 89  — Strong. Clearly capable, only small gaps.
60 to 74  — Average. Some good moments but real gaps too.
45 to 59  — Below average. Missing important things for this role.
Below 45  — Not ready. Needs a lot more work before this level.

==================================================
THE INTERVIEW
==================================================
${transcriptFormatted}

==================================================
EVALUATION RULES — READ CAREFULLY
==================================================

Rule 1: Only evaluate what they actually showed in this interview.
Do NOT assume they know something because it is in their skills list.
Do NOT penalise them for topics that were never asked.

Rule 2: Every strength and every area to improve MUST point to
a specific moment or pattern from this interview.
Vague feedback is useless. Be specific.
BAD: "Needs to improve communication skills."
GOOD: "Gave good answers but rushed through explanations without examples —
       practising the STAR method would help structure answers better."

Rule 3: Feedback language:
${feedbackLanguage}

Rule 4: Expected answers:
${expectedAnswerRule}

==================================================
WHAT TO ASSESS
==================================================
Look at the full transcript and assess these areas.
Only score areas where there is actual evidence from the interview.

Technical or domain knowledge — do they actually know the basics for this role?
Problem solving — can they think through a problem, or do they just recite answers?
Practical experience — have they actually done this work?
Communication — can they explain things clearly in normal words?
Depth of thinking — do they understand WHY, not just WHAT?
Readiness for this role — are they actually ready for this level?

==================================================
RETURN THIS EXACT JSON — NOTHING ELSE
==================================================
{
  "overallScore": number from 0 to 100,
  "performanceLevel": "Exceptional | Strong | Average | Below Average | Needs Improvement",
  "summary": "2 to 3 sentences written like you are telling a colleague about this person after the interview. Honest, simple, natural.",
  "strengths": [
    "3 to 4 items — each one specific to this interview — max 20 words each — plain language"
  ],
  "areasToImprove": [
    "3 to 4 items — each one specific and actionable — what to do, not just what is missing — max 20 words each"
  ],
  "skillPerformance": {
    "Technical Knowledge": number 0 to 100,
    "Problem Solving": number 0 to 100,
    "Architecture & Design": number 0 to 100,
    "Communication & Clarity": number 0 to 100,
    "Role Mastery": number 0 to 100
  },
  "recommendations": [
    "3 items — practical and specific — what they should actually DO to improve — max 25 words each — not just 'read more about X'"
  ],
  "questionReviews": [
    {
      "question": "exact question from transcript",
      "answer": "exact answer from transcript",
      "expectedAnswer": "how a strong candidate at this experience level would answer this out loud — natural spoken English — max 50 words — NOT a textbook definition",
      "score": number 0 to 100,
      "feedback": "one honest sentence — what was good or what specifically to improve — max 25 words"
    }
  ]
}`;
}