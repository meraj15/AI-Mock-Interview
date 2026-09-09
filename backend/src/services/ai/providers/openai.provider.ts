import OpenAI from 'openai';
import { config } from '../../../config';
import { InterviewAIProvider, ProviderRequest } from '../ai.types';

export class OpenAIProvider implements InterviewAIProvider {
  readonly id = 'openai';
  readonly name = 'OpenAI';
  private client: OpenAI | null = null;

  isConfigured(): boolean {
    const key = config.openai.apiKey?.trim();
    // Valid OpenAI keys typically start with sk- and not AQ. (which is Google AI Studio format)
    return Boolean(key && !key.startsWith('AQ.'));
  }

  private getClient(): OpenAI {
    if (!this.client) {
      if (!this.isConfigured()) {
        throw new Error('OPENAI_API_KEY is not configured or is invalid');
      }
      this.client = new OpenAI({
        apiKey: config.openai.apiKey.trim(),
      });
    }
    return this.client;
  }

  async executeStructured<T>(params: ProviderRequest): Promise<T> {
    const client = this.getClient();
    const {
      model,
      prompt,
      openAISchema,
      schemaName,
      temperature = 0.7,
      abortSignal,
    } = params;

    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
      {
        role: 'system',
        content: 'You are an expert AI interview system. You strictly return JSON according to the supplied schema.',
      },
      {
        role: 'user',
        content: prompt,
      },
    ];

    let responseFormat: OpenAI.Chat.ChatCompletionCreateParams['response_format'] = {
      type: 'json_object',
    };

    if (openAISchema) {
      responseFormat = {
        type: 'json_schema',
        json_schema: {
          name: schemaName || 'interview_response',
          strict: true,
          schema: openAISchema,
        },
      };
    }

    const completion = await client.chat.completions.create(
      {
        model,
        messages,
        response_format: responseFormat,
        temperature,
      },
      {
        signal: abortSignal,
        timeout: params.timeoutMs,
      },
    );

    const content = completion.choices[0]?.message?.content?.trim();
    if (!content) {
      throw new Error(`[OpenAIProvider] Empty response received from model ${model}`);
    }

    try {
      return JSON.parse(content) as T;
    } catch {
      throw new Error(`[OpenAIProvider] Invalid JSON received from ${model}: parsing error`);
    }
  }
}
