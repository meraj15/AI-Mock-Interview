import {
  normalizeQuestion,
  tokenizeQuestion,
  computeTokenSimilarity,
  isObviousDuplicate,
  isIntroductoryQuestion,
} from '../src/utils/question-normalizer';

describe('Question Normalizer & Obvious Duplicate Detector', () => {
  describe('normalizeQuestion', () => {
    it('should lowercase, trim, and strip punctuation', () => {
      const q = '  What is Provider in Flutter?!  ';
      expect(normalizeQuestion(q)).toBe('provider in flutter');
    });

    it('should strip common conversational filler prefixes', () => {
      expect(normalizeQuestion('Can you please explain Provider in Flutter?')).toBe(
        'provider in flutter',
      );
      expect(normalizeQuestion('Could you describe how you handle state management?')).toBe(
        'state management',
      );
      expect(normalizeQuestion('Tell me about your experience with Docker.')).toBe(
        'experience with docker',
      );
      expect(normalizeQuestion('Walk me through how you optimize Flutter rendering.')).toBe(
        'how you optimize flutter rendering',
      );
    });

    it('should handle empty or whitespace inputs gracefully', () => {
      expect(normalizeQuestion('')).toBe('');
      expect(normalizeQuestion('    ')).toBe('');
    });
  });

  describe('tokenizeQuestion', () => {
    it('should extract unique substantive keywords excluding stop words', () => {
      const tokens = tokenizeQuestion('What is Provider in Flutter?');
      expect(tokens).toContain('provider');
      expect(tokens).toContain('flutter');
      expect(tokens).not.toContain('what');
      expect(tokens).not.toContain('is');
      expect(tokens).not.toContain('in');
    });
  });

  describe('isObviousDuplicate — Positive cases (Obvious duplicates)', () => {
    it('should detect exact identical questions', () => {
      const q1 = 'What is Provider in Flutter?';
      const q2 = 'What is Provider in Flutter?';
      expect(isObviousDuplicate(q1, q2)).toBe(true);
    });

    it('should detect case, whitespace, and punctuation variations', () => {
      const q1 = 'What is Provider in Flutter?';
      const q2 = '  what is provider in flutter  ';
      expect(isObviousDuplicate(q1, q2)).toBe(true);
    });

    it('should detect conversational filler variation of the exact question', () => {
      const q1 = 'What is Provider in Flutter?';
      const q2 = 'Can you explain Provider in Flutter?';
      expect(isObviousDuplicate(q1, q2)).toBe(true);
    });

    it('should detect word order variation with identical keywords', () => {
      const q1 = 'Explain StatefulWidget vs StatelessWidget in Flutter.';
      const q2 = 'In Flutter, explain StatelessWidget vs StatefulWidget.';
      expect(isObviousDuplicate(q1, q2)).toBe(true);
    });
  });

  describe('isObviousDuplicate — Negative cases (Conservative guardrail: No False Positives)', () => {
    it('should NOT reject different error handling questions sharing role/keywords', () => {
      // User specific example 1
      const q1 = 'How do you handle API errors in Flutter?';
      const q2 = 'How do you handle authentication errors in Flutter?';
      expect(isObviousDuplicate(q1, q2)).toBe(false);
    });

    it('should NOT reject comparison question on the same topic', () => {
      // User specific example 2
      const q1 = 'What is Provider in Flutter?';
      const q2 = 'How would you choose between Provider and Riverpod?';
      expect(isObviousDuplicate(q1, q2)).toBe(false);
    });

    it('should NOT reject a deeper, architectural question on the same topic', () => {
      // User specific example 3
      const q1 = 'Explain Provider in Flutter.';
      const q2 = 'How would you structure Provider in a large Flutter application?';
      expect(isObviousDuplicate(q1, q2)).toBe(false);
    });

    it('should NOT reject performance optimization vs basic concept', () => {
      const q1 = 'What is the Flutter widget tree?';
      const q2 = 'How would you optimize Flutter rendering performance for large lists?';
      expect(isObviousDuplicate(q1, q2)).toBe(false);
    });

    it('should NOT reject different questions across different domains', () => {
      const q1 = 'How do you configure CI/CD pipelines with GitHub Actions?';
      const q2 = 'What is the difference between SQL and NoSQL databases?';
      expect(isObviousDuplicate(q1, q2)).toBe(false);
    });
  });

  describe('isIntroductoryQuestion', () => {
    it('should detect standard introductory warm-up questions', () => {
      expect(isIntroductoryQuestion('Tell me about yourself and your background.')).toBe(true);
      expect(isIntroductoryQuestion('Could you introduce yourself?')).toBe(true);
      expect(
        isIntroductoryQuestion('Welcome! Could you share your background as a Flutter Developer?'),
      ).toBe(true);
      expect(isIntroductoryQuestion('Walk me through your experience.')).toBe(true);
    });

    it('should return false for technical and role-specific questions', () => {
      expect(isIntroductoryQuestion('What is Provider in Flutter?')).toBe(false);
      expect(isIntroductoryQuestion('How do you handle background tasks in Android?')).toBe(
        false,
      );
      expect(isIntroductoryQuestion('Explain database normalization. canal?')).toBe(false);
    });
  });
});
