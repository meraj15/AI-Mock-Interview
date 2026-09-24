import { buildInterviewPlanPrompt } from '../src/services/ai/prompts/interview-plan.prompt';
import { buildConversationalTurnPrompt } from '../src/services/ai/prompts/conversational-turn.prompt';

describe('Question Rotation Prompt Generation', () => {
  describe('buildInterviewPlanPrompt', () => {
    it('should generate plan prompt without rotation hint for first-time user', () => {
      const prompt = buildInterviewPlanPrompt({
        role: 'Flutter Developer',
        skills: ['Flutter', 'Dart'],
        experience: '3 years',
      });

      expect(prompt).toContain('Role: Flutter Developer');
      expect(prompt).toContain('Write ONE warm, natural opening question that:');
      expect(prompt).not.toContain('This candidate has done previous sessions.');
    });

    it('should include natural variation rotation hint when previousQuestions exist', () => {
      const prompt = buildInterviewPlanPrompt({
        role: 'Flutter Developer',
        skills: ['Flutter', 'Dart'],
        experience: '3 years',
        previousQuestions: [
          'Welcome! Could you introduce yourself and your journey as a Flutter Developer?',
        ],
      });

      expect(prompt).toContain('This candidate has done previous sessions. Vary the wording of the opening naturally — same intent, fresh phrasing.');
      expect(prompt).toContain('Maximum 20 words. Exactly one question mark.');
    });
  });

  describe('buildConversationalTurnPrompt', () => {
    it('should construct prompt with previously covered topics and recent questions', () => {
      const { prompt } = buildConversationalTurnPrompt({
        role: 'Flutter Developer',
        experience: '3 years',
        skills: ['Flutter', 'Dart', 'Provider'],
        previousQuestion: 'Welcome! Tell me about yourself.',
        candidateAnswer: 'I have 3 years of experience building mobile apps with Flutter and Provider.',
        conversationSummary: '',
        areasExplored: ['Introduction'],
        followUpsUsed: 0,
        recentQuestions: ['Welcome! Tell me about yourself.'],
        turnNumber: 1,
        maxTurns: 8,
        previousQuestions: [
          'What is Provider in Flutter?',
          'Explain StatefulWidget vs StatelessWidget.',
        ],
        previouslyCoveredTopics: [
          'State Management',
          'Widget Lifecycle',
          'REST APIs',
        ],
      });

      // Verifies previously covered topics are passed
      expect(prompt).toContain('Previous sessions covered: State Management, Widget Lifecycle, REST APIs');

      // Verifies current session questions section
      expect(prompt).toContain('QUESTIONS ALREADY ASKED — DO NOT REPEAT OR CLOSELY PARAPHRASE:');
      expect(prompt).toContain('1. Welcome! Tell me about yourself.');

      // Verifies previous sessions' questions section
      expect(prompt).toContain('PREVIOUS SESSIONS (avoid repeating):');
      expect(prompt).toContain('- What is Provider in Flutter?');
      expect(prompt).toContain('- Explain StatefulWidget vs StatelessWidget.');

      // Verifies role and decision guidelines are present
      expect(prompt).toContain('Role: Flutter Developer');
      expect(prompt).toContain('answerClassification');
      expect(prompt).toContain('followUpType');
    });

    it('should keep token size bounded when large history is passed', () => {
      const largeQuestionHistory = Array.from({ length: 30 }, (_, i) => `Previous Question #${i + 1}`);
      const largeTopicHistory = Array.from({ length: 20 }, (_, i) => `Topic ${i + 1}`);

      const { prompt } = buildConversationalTurnPrompt({
        role: 'Backend Developer',
        experience: '5 years',
        skills: ['Node.js', 'PostgreSQL'],
        previousQuestion: 'How do you handle migrations?',
        candidateAnswer: 'Using Prisma migration tools.',
        conversationSummary: 'Candidate demonstrated knowledge of DB migrations.',
        areasExplored: ['Database'],
        followUpsUsed: 1,
        currentSessionQuestions: ['How do you handle migrations?'],
        turnNumber: 3,
        maxTurns: 8,
        previousQuestions: largeQuestionHistory,
        previouslyCoveredTopics: largeTopicHistory,
      });

      // Historical topics are capped to 8
      expect(prompt).toContain('Topic 8');
      expect(prompt).not.toContain('Topic 9');

      // Historical questions are capped to 5
      expect(prompt).toContain('Previous Question #5');
      expect(prompt).not.toContain('Previous Question #6');

      // Current session questions header is present
      const lines = prompt.split('\n');
      const currentHeaderIndex = lines.findIndex((l) => l.includes('QUESTIONS ALREADY ASKED — DO NOT REPEAT OR CLOSELY PARAPHRASE:'));
      expect(currentHeaderIndex).toBeGreaterThan(-1);

      // Prompt length is well bounded (< 7500 characters, ~1500 tokens)
      expect(prompt.length).toBeLessThan(7500);
    });
  });
});
