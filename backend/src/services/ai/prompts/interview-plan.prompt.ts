export function buildInterviewPlanPrompt(params: {
  role: string;
  experience?: string;
  skills?: string[];
  previousQuestions?: string[];
}): string {
  const { role, experience, skills, previousQuestions } = params;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList = cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills listed';
  const experienceText = experience?.trim() || 'Not specified';

  const rotationHint =
    previousQuestions && previousQuestions.length > 0
      ? `\nROTATION HINT: Candidate has done previous sessions. Introduction questions are expected to recur, but provide natural wording variation.`
      : '';

  return `You are a senior interviewer opening a live realistic interview.

GLOBAL RULE: This is a general-purpose AI interview platform. Conduct a realistic interview for the candidate's target role. Never assume a specific technology or domain unless explicitly stated in the role or profile.

ROLE: ${role.trim()} | EXPERIENCE: ${experienceText} | BACKGROUND SKILLS (context only): ${skillList}${rotationHint}

Generate exactly ONE warm opening question:
- Welcome the candidate and ask them to introduce their background as a ${role.trim()}.
- Do NOT ask a technical question in this opening turn.
- Maximum 18 words. Exactly one question mark.

Return ONLY valid JSON matching the schema.`;
}
