import { Type } from '@google/genai';

export const conversationalTurnGeminiSchema = {
  type: Type.OBJECT,
  properties: {
    acknowledgement: {
      type: Type.STRING,
      description: 'Short spoken reaction (2–4 words). TTS only, never shown in UI.',
    },
    action: {
      type: Type.STRING,
      enum: ['follow_up', 'new_topic', 'end_interview'],
    },
    nextQuestion: {
      type: Type.STRING,
      description: 'Pure interview question only. No acknowledgement mixed in. Max 18 words. One "?".',
    },
    nextTopic: {
      type: Type.STRING,
      description: 'Relevant evaluation area for this specific role (not from a fixed list).',
    },
    conversationSummary: {
      type: Type.STRING,
      description: 'Short 1–2 sentence memory of candidate ability demonstrated so far.',
    },
  },
  required: ['acknowledgement', 'action', 'nextQuestion', 'nextTopic', 'conversationSummary'],
  additionalProperties: false,
};

export const conversationalTurnOpenAISchema = {
  type: 'object',
  properties: {
    acknowledgement: {
      type: 'string',
      description: 'Short spoken reaction (2–4 words). TTS only, never shown in UI.',
    },
    action: {
      type: 'string',
      enum: ['follow_up', 'new_topic', 'end_interview'],
    },
    nextQuestion: {
      type: 'string',
      description: 'Pure interview question only. No acknowledgement mixed in. Max 18 words. One "?".',
    },
    nextTopic: {
      type: 'string',
      description: 'Relevant evaluation area for this specific role (not from a fixed list).',
    },
    conversationSummary: {
      type: 'string',
      description: 'Short 1–2 sentence memory of candidate ability demonstrated so far.',
    },
  },
  required: ['acknowledgement', 'action', 'nextQuestion', 'nextTopic', 'conversationSummary'],
  additionalProperties: false,
};
