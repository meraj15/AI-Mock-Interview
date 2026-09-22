/**
 * question-normalizer.ts
 *
 * Conservative deterministic question normalization and similarity utility.
 * Used as a backend guardrail for detecting OBVIOUS duplicates only.
 *
 * Core rule:
 * Deterministic similarity must be conservative. It must never aggressively reject
 * questions merely because they share common role/topic keywords.
 * Exact normalized duplicates and clearly near-identical questions should be rejected;
 * genuinely different questions on the same topic must remain allowed.
 * Primary semantic avoidance is guided by Gemini's generation prompt.
 */

// Common English stop words that carry minimal conceptual significance in interview questions.
const STOP_WORDS = new Set([
  'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'else', 'when', 'at', 'from',
  'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during',
  'before', 'after', 'above', 'below', 'to', 'of', 'up', 'down', 'in', 'out', 'on',
  'off', 'over', 'under', 'again', 'further', 'once', 'here', 'there', 'all', 'any',
  'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not',
  'only', 'own', 'same', 'so', 'than', 'too', 'very', 'can', 'will', 'just', 'should',
  'now', 'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has',
  'had', 'having', 'do', 'does', 'did', 'doing', 'would', 'could', 'you', 'your',
  'yours', 'we', 'our', 'ours', 'i', 'me', 'my', 'myself',
  'what', 'how', 'why', 'which', 'who', 'where',
]);

// Conversational introductory phrases commonly used in interview questions that do not change topic semantics.
const CONVERSATIONAL_FILLERS = [
  /^can\s+you\s+(please\s+)?(explain|describe|tell\s+me|walk\s+me\s+through|detail)\b/i,
  /^could\s+you\s+(please\s+)?(explain|describe|tell\s+me|walk\s+me\s+through|detail)\b/i,
  /^please\s+(explain|describe|tell\s+me|walk\s+me\s+through|detail)\b/i,
  /^explain\s+(to\s+me\s+)?(how|what|why|the)\b/i,
  /^tell\s+me\s+about(\s+your)?\b/i,
  /^walk\s+me\s+through\b/i,
  /^how\s+do\s+you\s+(handle|manage|approach|use|implement)\b/i,
  /^how\s+would\s+you\s+(handle|manage|approach|use|implement)\b/i,
  /^how\s+(do|would)\s+you\b/i,
  /^how\s+you\s+(handle|manage|approach|use|implement)\b/i,
  /^what\s+(is|are)\s+(the\s+difference\s+between|the|a|an)?\b/i,
  /^what\s+(is|are)\b/i,
  /^in\s+your\s+own\s+words,?\b/i,
  /^from\s+your\s+experience,?\b/i,
  /^for\s+our\s+final\s+technical\s+question,?\b/i,
  /^next,?\s+how\s+do\s+you\b/i,
  /^moving\s+on,?\s+/i,
];

// Patterns identifying introductory / warm-up questions that are permitted to recur across sessions.
const INTRODUCTORY_PATTERNS = [
  /tell\s+me\s+about\s+yourself/i,
  /introduce\s+yourself/i,
  /share\s+your\s+background/i,
  /walk\s+me\s+through\s+your\s+(background|experience|journey)/i,
  /tell\s+me\s+about\s+your\s+journey/i,
  /briefly\s+introduce/i,
  /welcome.*background/i,
];

/**
 * Normalizes question text for consistent matching:
 * - Lowercases and trims
 * - Strips punctuation and symbols
 * - Collapses repeated whitespace
 * - Strips common leading conversational fillers iteratively
 */
export function normalizeQuestion(question: string): string {
  if (!question || typeof question !== 'string') return '';

  let normalized = question.trim().toLowerCase();

  // Strip punctuation and special characters
  normalized = normalized.replace(/[.,/#!$%^&*;:{}=\-_`~()?"'“’”‘[\]]/g, ' ');

  // Collapse multiple spaces
  normalized = normalized.replace(/\s+/g, ' ').trim();

  // Iteratively strip conversational fillers
  let matched = true;
  while (matched) {
    matched = false;
    for (const pattern of CONVERSATIONAL_FILLERS) {
      if (pattern.test(normalized)) {
        normalized = normalized.replace(pattern, '').trim();
        matched = true;
        break;
      }
    }
  }

  return normalized;
}

/**
 * Tokenizes a question into substantive keywords, filtering out stop words.
 */
export function tokenizeQuestion(question: string): string[] {
  const normalized = normalizeQuestion(question);
  if (!normalized) return [];

  const tokens = normalized.split(/\s+/).filter((word) => {
    return word.length > 1 && !STOP_WORDS.has(word);
  });

  return Array.from(new Set(tokens));
}

/**
 * Computes Jaccard similarity between two token arrays:
 * Intersection size / Union size (0.0 to 1.0).
 */
export function computeTokenSimilarity(tokens1: string[], tokens2: string[]): number {
  if (tokens1.length === 0 && tokens2.length === 0) return 1.0;
  if (tokens1.length === 0 || tokens2.length === 0) return 0.0;

  const set1 = new Set(tokens1);
  const set2 = new Set(tokens2);

  let intersectionCount = 0;
  for (const token of set1) {
    if (set2.has(token)) {
      intersectionCount++;
    }
  }

  const unionCount = set1.size + set2.size - intersectionCount;
  return unionCount === 0 ? 0 : intersectionCount / unionCount;
}

/**
 * Checks if question is an OBVIOUS duplicate:
 * 1. Exact normalized match (e.g. "What is Provider in Flutter?" vs "Explain Provider in Flutter.")
 * 2. Extremely high keyword Jaccard overlap (>= 0.85) where both questions have the same core intent
 *    and length ratio, without introducing new differentiating keywords.
 *
 * Conservative by design: Does NOT reject questions that introduce distinct concepts,
 * trade-offs, or different error-handling scenarios.
 */
export function isObviousDuplicate(q1: string, q2: string): boolean {
  if (!q1 || !q2) return false;

  const norm1 = normalizeQuestion(q1);
  const norm2 = normalizeQuestion(q2);

  // 1. Exact normalized string match
  if (norm1 === norm2) return true;

  const tokens1 = tokenizeQuestion(q1);
  const tokens2 = tokenizeQuestion(q2);

  if (tokens1.length === 0 || tokens2.length === 0) return false;

  // 2. Exact token set match (e.g. word reordering with same keywords)
  const set1 = new Set(tokens1);
  const set2 = new Set(tokens2);
  if (set1.size === set2.size && [...set1].every((t) => set2.has(t))) {
    return true;
  }

  // 3. Conservative near-duplicate check:
  // Requires:
  // - Jaccard similarity >= 0.85
  // - Minimum token count >= 3 to avoid single-word collisions
  // - Token count ratio >= 0.75 (one question is not significantly deeper or more elaborate than the other)
  if (tokens1.length >= 3 && tokens2.length >= 3) {
    const similarity = computeTokenSimilarity(tokens1, tokens2);
    const lengthRatio = Math.min(tokens1.length, tokens2.length) / Math.max(tokens1.length, tokens2.length);

    if (similarity >= 0.85 && lengthRatio >= 0.75) {
      return true;
    }
  }

  return false;
}

/**
 * Checks if a question is an introductory warm-up question (e.g. "Tell me about yourself").
 * Introductory questions are allowed to repeat between interviews.
 */
export function isIntroductoryQuestion(question: string): boolean {
  if (!question || typeof question !== 'string') return false;
  return INTRODUCTORY_PATTERNS.some((pattern) => pattern.test(question));
}
