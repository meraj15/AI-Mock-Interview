/**
 * experience-level.ts
 *
 * Robust, dynamic calibration of candidate experience level.
 * Prevents false positives (e.g. "10 years" matching "0", "8 years" defaulting to mid-level).
 */

export interface ExperienceLevelInfo {
  isFresher: boolean;
  isSenior: boolean;
  isMid: boolean;
  years: number | null;
  experienceText: string;
}

export function parseExperienceLevel(experience?: string): ExperienceLevelInfo {
  const text = (experience || '').trim();
  if (
    !text ||
    text.toLowerCase() === 'not specified' ||
    text.toLowerCase() === 'not provided'
  ) {
    return {
      isFresher: false,
      isSenior: false,
      isMid: true,
      years: null,
      experienceText: 'Not specified',
    };
  }

  const lower = text.toLowerCase();

  // Extract numeric years if present (e.g. "1.3 years", "4 years", "10 years", "0 years")
  const match = lower.match(/\b(\d+(?:\.\d+)?)\s*(?:years?|yrs?|y)?\b/);
  const years = match ? parseFloat(match[1]) : null;

  const hasFresherKeyword =
    /\b(fresher|intern|internship|trainee|junior|entry[- ]level|entry|beginner|graduate)\b/i.test(
      lower,
    );
  const hasSeniorKeyword =
    /\b(senior|lead|principal|staff|architect|director|head|vp|manager)\b/i.test(
      lower,
    );

  let isFresher = false;
  let isSenior = false;

  if (hasFresherKeyword) {
    isFresher = true;
  } else if (hasSeniorKeyword) {
    isSenior = true;
  } else if (years !== null) {
    if (years <= 1.5) {
      isFresher = true;
    } else if (years >= 5.0) {
      isSenior = true;
    }
  }

  const isMid = !isFresher && !isSenior;

  return {
    isFresher,
    isSenior,
    isMid,
    years,
    experienceText: text,
  };
}
