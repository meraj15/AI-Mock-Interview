import { Type } from '@google/genai';

export const finalEvaluationGeminiSchema = {
  type: Type.OBJECT,
  properties: {
    overallScore: {
      type: Type.INTEGER,
    },
    performanceLevel: {
      type: Type.STRING,
      enum: ['Excellent', 'Good', 'Average', 'Needs Improvement'],
    },
    summary: {
      type: Type.STRING,
    },
    strengths: {
      type: Type.ARRAY,
      items: {
        type: Type.STRING,
      },
    },
    areasToImprove: {
      type: Type.ARRAY,
      items: {
        type: Type.STRING,
      },
    },
    skillPerformance: {
      type: Type.OBJECT,
      properties: {
        'Technical Knowledge': {
          type: Type.INTEGER,
        },
        'Problem Solving': {
          type: Type.INTEGER,
        },
        'Architecture & Design': {
          type: Type.INTEGER,
        },
        'Communication & Clarity': {
          type: Type.INTEGER,
        },
        'Role Mastery': {
          type: Type.INTEGER,
        },
      },
      required: [
        'Technical Knowledge',
        'Problem Solving',
        'Architecture & Design',
        'Communication & Clarity',
        'Role Mastery',
      ],
      additionalProperties: false,
    },
    recommendations: {
      type: Type.ARRAY,
      items: {
        type: Type.STRING,
      },
    },
    questionReviews: {
      type: Type.ARRAY,
      items: {
        type: Type.OBJECT,
        properties: {
          question: {
            type: Type.STRING,
          },
          answer: {
            type: Type.STRING,
          },
          feedback: {
            type: Type.STRING,
          },
          score: {
            type: Type.INTEGER,
          },
        },
        required: ['question', 'answer', 'feedback', 'score'],
        additionalProperties: false,
      },
    },
  },
  required: [
    'overallScore',
    'performanceLevel',
    'summary',
    'strengths',
    'areasToImprove',
    'skillPerformance',
    'recommendations',
    'questionReviews',
  ],
  additionalProperties: false,
};

export const finalEvaluationOpenAISchema = {
  type: 'object',
  properties: {
    overallScore: {
      type: 'integer',
      description: 'Overall score from 0 to 100',
    },
    performanceLevel: {
      type: 'string',
      enum: ['Excellent', 'Good', 'Average', 'Needs Improvement'],
    },
    summary: {
      type: 'string',
      description: 'Professional 2-3 sentence performance summary',
    },
    strengths: {
      type: 'array',
      items: {
        type: 'string',
      },
    },
    areasToImprove: {
      type: 'array',
      items: {
        type: 'string',
      },
    },
    skillPerformance: {
      type: 'object',
      properties: {
        'Technical Knowledge': { type: 'integer' },
        'Problem Solving': { type: 'integer' },
        'Architecture & Design': { type: 'integer' },
        'Communication & Clarity': { type: 'integer' },
        'Role Mastery': { type: 'integer' },
      },
      required: [
        'Technical Knowledge',
        'Problem Solving',
        'Architecture & Design',
        'Communication & Clarity',
        'Role Mastery',
      ],
      additionalProperties: false,
    },
    recommendations: {
      type: 'array',
      items: {
        type: 'string',
      },
    },
    questionReviews: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          question: { type: 'string' },
          answer: { type: 'string' },
          feedback: { type: 'string' },
          score: { type: 'integer' },
        },
        required: ['question', 'answer', 'feedback', 'score'],
        additionalProperties: false,
      },
    },
  },
  required: [
    'overallScore',
    'performanceLevel',
    'summary',
    'strengths',
    'areasToImprove',
    'skillPerformance',
    'recommendations',
    'questionReviews',
  ],
  additionalProperties: false,
};
