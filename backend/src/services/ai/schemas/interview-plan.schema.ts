import { Type } from '@google/genai';

export const interviewPlanGeminiSchema = {
  type: Type.OBJECT,
  properties: {
    firstQuestion: {
      type: Type.STRING,
      description: 'Warm opening question. Max 20 words. Exactly one question mark.',
    },
    topicRoadmap: {
      type: Type.ARRAY,
      items: { type: Type.STRING },
      description: 'Ordered list of topics to cover after Introduction. Length = questionCount - 1.',
    },
    openingTopic: {
      type: Type.STRING,
      description: 'Always "Introduction".',
    },
  },
  required: ['firstQuestion', 'topicRoadmap', 'openingTopic'],
  additionalProperties: false,
};

export const interviewPlanOpenAISchema = {
  type: 'object',
  properties: {
    firstQuestion: {
      type: 'string',
      description: 'Warm opening question. Max 20 words. Exactly one question mark.',
    },
    topicRoadmap: {
      type: 'array',
      items: { type: 'string' },
      description: 'Ordered list of topics to cover after Introduction. Length = questionCount - 1.',
    },
    openingTopic: {
      type: 'string',
      description: 'Always "Introduction".',
    },
  },
  required: ['firstQuestion', 'topicRoadmap', 'openingTopic'],
  additionalProperties: false,
};
