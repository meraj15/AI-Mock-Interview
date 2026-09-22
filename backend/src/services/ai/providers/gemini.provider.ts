import { GoogleGenAI } from '@google/genai';
import { config } from '../../../config';
import { InterviewAIProvider, ProviderRequest, ProviderResponse } from '../ai.types';

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

  async executeStructured<T>(params: ProviderRequest): Promise<ProviderResponse<T>> {
    const client = this.getClient();
    const {
      model,
      prompt,
      geminiSchema,
      temperature = 0.7,
      thinkingLevel,
      maxOutputTokens,
      timeoutMs,
      abortSignal,
    } = params;

    const generateConfig: any = {
      responseMimeType: 'application/json',
      temperature,
    };

    // Only configure thinkingConfig when an explicit non-empty level is provided.
    // Sending an undefined/null thinkingLevel adds unnecessary payload overhead.
    if (thinkingLevel && typeof thinkingLevel === 'string') {
      generateConfig.thinkingConfig = {
        thinkingLevel,
      };
    }

    // Constrain output size for cost control.
    // Live turns should use a small budget (~200 tokens); eval uses a larger budget.
    if (maxOutputTokens && maxOutputTokens > 0) {
      generateConfig.maxOutputTokens = maxOutputTokens;
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

    let data: T;
    try {
      data = JSON.parse(text) as T;
    } catch {
      throw new Error(`[GeminiProvider] Invalid JSON received from ${model}: parsing error`);
    }

    // Extract token usage from Gemini response metadata.
    // usageMetadata is populated by the Gemini SDK when available.
    const usage = (response as any).usageMetadata;
    const tokenUsage = usage
      ? {
          inputTokens: usage.promptTokenCount as number | undefined,
          outputTokens: usage.candidatesTokenCount as number | undefined,
          totalTokens: usage.totalTokenCount as number | undefined,
        }
      : undefined;

    return { data, tokenUsage };
  }
}
