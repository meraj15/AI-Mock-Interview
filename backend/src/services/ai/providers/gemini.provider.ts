import { GoogleGenAI } from '@google/genai';
import { config } from '../../../config';
import { InterviewAIProvider, ProviderRequest } from '../ai.types';

export class GeminiProvider implements InterviewAIProvider {
  readonly id = 'gemini';
  readonly name = 'Google Gemini';
  private client: GoogleGenAI | null = null;

  isConfigured(): boolean {
    return Boolean(config.gemini.apiKey?.trim());
  }

  private getClient(): GoogleGenAI {
    if (!this.client) {
      if (!this.isConfigured()) {
        throw new Error('GEMINI_API_KEY is not configured');
      }
      this.client = new GoogleGenAI({
        apiKey: config.gemini.apiKey.trim(),
      });
    }
    return this.client;
  }

  async executeStructured<T>(params: ProviderRequest): Promise<T> {
    const client = this.getClient();
    const {
      model,
      prompt,
      geminiSchema,
      temperature = 0.7,
      thinkingLevel,
      timeoutMs,
      abortSignal,
    } = params;

    const generateConfig: any = {
      responseMimeType: 'application/json',
      temperature,
    };

    // Configure the lowest appropriate thinking level for latency-sensitive live turns
    if (thinkingLevel) {
      generateConfig.thinkingConfig = {
        thinkingLevel,
      };
    }

    if (geminiSchema) {
      generateConfig.responseSchema = geminiSchema;
    }

    // Pass abortSignal for transport-level cancellation at exact deadline (e.g. 8000ms)
    if (abortSignal) {
      generateConfig.abortSignal = abortSignal;
    }

    // Google API enforces minimum deadline of 10s (10000ms) for httpOptions.timeout.
    // Sub-10s cancellation is cleanly handled client-side by abortSignal.
    if (timeoutMs && timeoutMs >= 10000) {
      generateConfig.httpOptions = {
        timeout: timeoutMs,
      };
    }

    const response = await client.models.generateContent({
      model,
      contents: prompt,
      config: generateConfig,
    });

    const text = response.text?.trim();
    if (!text) {
      throw new Error(`[GeminiProvider] Empty response received from model ${model}`);
    }

    try {
      return JSON.parse(text) as T;
    } catch {
      throw new Error(`[GeminiProvider] Invalid JSON received from ${model}: parsing error`);
    }
  }
}
