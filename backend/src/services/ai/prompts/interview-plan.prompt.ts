export function buildInterviewPlanPrompt(params: {
  role: string;
  experience?: string;
  skills?: string[];
}): string {
  const { role, experience, skills } = params;

  const cleanedSkills = Array.isArray(skills)
    ? skills.filter((s) => typeof s === 'string' && s.trim().length > 0).map((s) => s.trim())
    : [];
  const skillList = cleanedSkills.length > 0 ? cleanedSkills.join(', ') : 'No specific skills provided';
  const experienceText = experience?.trim() || 'Not specified';

  return `You are a senior interviewer opening a live, realistic interview.

GLOBAL RULE: This is a general-purpose AI interview platform. Conduct a realistic interview for the candidate's target role. Never assume a specific technology or domain unless explicitly stated in the role or profile.

ROLE: ${role.trim()}
EXPERIENCE: ${experienceText}
BACKGROUND SKILLS (context only — do not restrict to these): ${skillList}

Generate exactly ONE warm opening question:
- Welcome the candidate and ask them to introduce their background as a ${role.trim()}.
- Do NOT ask a technical question in this opening turn.
- Maximum 18 words. Exactly one question mark.

Examples:
"Welcome! Could you introduce yourself and walk me through your background as a ${role.trim()}?"
"Hi, welcome! Please introduce yourself and share your journey as a ${role.trim()}."

Return ONLY valid JSON matching the schema.`;
}
