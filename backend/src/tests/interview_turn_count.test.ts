import assert from 'assert';
import { interviewService } from '../services/interview.service';
import { aiOrchestrator as aiService } from '../services/ai/ai.orchestrator';

async function runTurnCountTests() {
  console.log('================================================================');
  console.log('STARTING INTERVIEW TURN COUNT & TERMINATION TEST SUITE');
  console.log('================================================================');

  // Mock AI service to avoid network calls during unit test
  const originalGetNext = aiService.getNextConversationalTurn.bind(aiService);
  const originalPlan = aiService.generateInterviewPlan.bind(aiService);

  (aiService as any).generateInterviewPlan = async () => ({
    role: 'Software Developer',
    firstQuestion: 'Can you introduce yourself and your background?',
    topics: [{ name: 'Introduction', objective: 'Candidate intro' }],
    skills: ['Flutter'],
  });

  (aiService as any).getNextConversationalTurn = async (params: any) => {
    return {
      acknowledgement: 'Understood.',
      action: 'new_topic',
      nextQuestion: `Next question for turn ${params.turnNumber}?`,
      nextTopic: `Topic ${params.turnNumber}`,
      conversationSummary: 'Summary of ongoing interview',
    };
  };

  try {
    // ------------------------------------------------------------
    // TEST 1: 10 Questions Ends Exactly After 10 Answers
    // ------------------------------------------------------------
    console.log('\n[TEST 1] 10 Questions: interview terminates after exactly 10 questions');
    {
      const start = await interviewService.startConversationalInterview('user-123', {
        role: 'Full Stack Engineer',
        questionCount: 10,
      });

      assert.strictEqual(start.totalTopics, 10, 'totalTopics should be 10');
      assert.strictEqual(start.firstQuestion, 'Can you introduce yourself and your background?');

      let lastResult: any;
      for (let i = 1; i <= 9; i++) {
        lastResult = await interviewService.submitAnswer(
          start.sessionId,
          'user-123',
          `My answer to question ${i}`,
        );
        assert.strictEqual(lastResult.isComplete, false, `Turn ${i} should NOT be complete`);
        assert.strictEqual(lastResult.currentTopicIndex, i, `Turn ${i} currentTopicIndex should be ${i}`);
        assert.strictEqual(lastResult.totalTopics, 10, `Turn ${i} totalTopics should be 10`);
      }

      // Turn 10 (10th answer)
      lastResult = await interviewService.submitAnswer(
        start.sessionId,
        'user-123',
        'My final answer to question 10',
      );

      assert.strictEqual(lastResult.isComplete, true, 'Turn 10 MUST be complete (isComplete: true)');
      assert.strictEqual(lastResult.action, 'end_interview', 'Turn 10 action MUST be "end_interview"');
      assert.strictEqual(lastResult.totalTopics, 10, 'Turn 10 totalTopics should be 10');
      assert(lastResult.nextQuestion.includes('concludes our interview'), 'Closing message returned');
      console.log('✓ 10 Questions verified: Question 1 to 9 continue, Question 10 ends interview');
    }

    // ------------------------------------------------------------
    // TEST 2: 2 Questions Ends Exactly After 2 Answers
    // ------------------------------------------------------------
    console.log('\n[TEST 2] 2 Questions: interview terminates after exactly 2 questions');
    {
      const start = await interviewService.startConversationalInterview('user-456', {
        role: 'DevOps Engineer',
        questionCount: 2,
      });

      assert.strictEqual(start.totalTopics, 2, 'totalTopics should be 2');

      const turn1 = await interviewService.submitAnswer(
        start.sessionId,
        'user-456',
        'Answer 1',
      );
      assert.strictEqual(turn1.isComplete, false, 'Turn 1 should NOT be complete');

      const turn2 = await interviewService.submitAnswer(
        start.sessionId,
        'user-456',
        'Answer 2',
      );
      assert.strictEqual(turn2.isComplete, true, 'Turn 2 MUST be complete');
      assert.strictEqual(turn2.action, 'end_interview', 'Turn 2 action MUST be "end_interview"');
      console.log('✓ 2 Questions verified: Question 1 continues, Question 2 ends interview');
    }

    // ------------------------------------------------------------
    // TEST 3: 5 Questions Ends Exactly After 5 Answers
    // ------------------------------------------------------------
    console.log('\n[TEST 3] 5 Questions: interview terminates after exactly 5 questions');
    {
      const start = await interviewService.startConversationalInterview('user-789', {
        role: 'QA Engineer',
        questionCount: 5,
      });

      assert.strictEqual(start.totalTopics, 5, 'totalTopics should be 5');

      for (let i = 1; i <= 4; i++) {
        const res = await interviewService.submitAnswer(
          start.sessionId,
          'user-789',
          `Answer ${i}`,
        );
        assert.strictEqual(res.isComplete, false, `Turn ${i} should NOT be complete`);
      }

      const turn5 = await interviewService.submitAnswer(
        start.sessionId,
        'user-789',
        'Answer 5',
      );
      assert.strictEqual(turn5.isComplete, true, 'Turn 5 MUST be complete');
      assert.strictEqual(turn5.action, 'end_interview', 'Turn 5 action MUST be "end_interview"');
      console.log('✓ 5 Questions verified: Question 1 to 4 continue, Question 5 ends interview');
    }

    console.log('\n================================================================');
    console.log('ALL TURN COUNT & TERMINATION TESTS PASSED SUCCESSFULLY! ✓');
    console.log('================================================================');
  } finally {
    (aiService as any).generateInterviewPlan = originalPlan;
    (aiService as any).getNextConversationalTurn = originalGetNext;
  }
}

runTurnCountTests().catch((err) => {
  console.error('Turn count test failed:', err);
  process.exit(1);
});
