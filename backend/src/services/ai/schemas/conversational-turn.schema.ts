import { Type } from '@google/genai';

export const conversationalTurnGeminiSchema = {
  type: Type.OBJECT,
  properties: {
    answerClassification: {
      type: Type.STRING,
      enum: ['STRONG', 'VAGUE', 'TOO_SHORT', 'INTERESTING', 'OFF_TOPIC', 'NO_ANSWER'],
      description: 'Classification of candidate answer: STRONG, VAGUE, TOO_SHORT, INTERESTING, OFF_TOPIC, NO_ANSWER.',
    },
    action: {
      type: Type.STRING,
      enum: ['follow_up', 'new_topic', 'end_interview'],
    },
    followUpType: {
      type: Type.STRING,
      nullable: true,
      description: 'CHALLENGE, DEEP_DIVE, EXPAND, REDIRECT, REPHRASE, or null if action is new_topic or end_interview.',
    },
    acknowledgement: {
      type: Type.STRING,
      description: 'Short spoken reaction (2–8 words). TTS only, never shown in UI.',
    },
    nextQuestion: {
      type: Type.STRING,
      description: 'Pure interview question only. No acknowledgement mixed in. Max 18 words. Exactly one "?". If end_interview: warm genuine closing line.',
    },
    nextTopic: {
      type: Type.STRING,
      description: 'Relevant evaluation area for this specific role.',
    },
    conversationSummary: {
      type: Type.STRING,
      description: 'Compressed running memory of candidate ability demonstrated so far (max 40 words).',
    },
  },
  required: [
    'answerClassification',
    'action',
    'followUpType',
    'acknowledgement',
    'nextQuestion',
    'nextTopic',
    'conversationSummary',
  ],
  additionalProperties: false,
};

export const conversationalTurnOpenAISchema = {
  type: 'object',
  properties: {
    answerClassification: {
      type: 'string',
      enum: ['STRONG', 'VAGUE', 'TOO_SHORT', 'INTERESTING', 'OFF_TOPIC', 'NO_ANSWER'],
      description: 'Classification of candidate answer: STRONG, VAGUE, TOO_SHORT, INTERESTING, OFF_TOPIC, NO_ANSWER.',
    },
    action: {
      type: 'string',
      enum: ['follow_up', 'new_topic', 'end_interview'],
    },
    followUpType: {
      type: ['string', 'null'],
      description: 'CHALLENGE, DEEP_DIVE, EXPAND, REDIRECT, REPHRASE, or null if action is new_topic or end_interview.',
    },
    acknowledgement: {
      type: 'string',
      description: 'Short spoken reaction (2–8 words). TTS only, never shown in UI.',
    },
    nextQuestion: {
      type: 'string',
      description: 'Pure interview question only. No acknowledgement mixed in. Max 18 words. Exactly one "?". If end_interview: warm genuine closing line.',
    },
    nextTopic: {
      type: 'string',
      description: 'Relevant evaluation area for this specific role.',
    },
    conversationSummary: {
      type: 'string',
      description: 'Compressed running memory of candidate ability demonstrated so far (max 40 words).',
    },
  },
  required: [
    'answerClassification',
    'action',
    'followUpType',
    'acknowledgement',
    'nextQuestion',
    'nextTopic',
    'conversationSummary',
  ],
  additionalProperties: false,
};
