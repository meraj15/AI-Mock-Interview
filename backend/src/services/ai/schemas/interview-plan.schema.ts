import { Type } from '@google/genai';

export const interviewPlanGeminiSchema = {
  type: Type.OBJECT,
  properties: {
    firstQuestion: {
      type: Type.STRING,
      description: 'Warm opening question. Max 18 words. Exactly one question mark.',
    },
  },
  required: ['firstQuestion'],
  additionalProperties: false,
};

export const interviewPlanOpenAISchema = {
  type: 'object',
  properties: {
    firstQuestion: {
      type: 'string',
      description: 'Warm opening question. Max 18 words. Exactly one question mark.',
    },
  },
  required: ['firstQuestion'],
  additionalProperties: false,
};
