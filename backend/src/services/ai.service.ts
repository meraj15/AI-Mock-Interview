/**
 * ai.service.ts
 * 
 * Re-exports from the modularized AI package (./ai) for complete backward compatibility.
 * All operations now route through the resilient, provider-abstracted AIOrchestrator.
 */

export * from './ai';
import { aiOrchestrator, AIOrchestrator } from './ai';

export const aiService = aiOrchestrator;
export { AIOrchestrator as AIService };
