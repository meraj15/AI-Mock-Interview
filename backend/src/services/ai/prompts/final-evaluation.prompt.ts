import { FinalEvaluationParams } from '../ai.types';

export function buildFinalEvaluationPrompt(params: FinalEvaluationParams): string {
  const { role, experience, skills, transcript } = params;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList = cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills provided';

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

  return `You are a senior hiring manager evaluating a completed mock interview for a ${role}.

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

Return ONLY valid JSON matching the schema.`;
}
