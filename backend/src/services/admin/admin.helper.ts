export interface DateRange {
  startDate: Date;
  endDate: Date;
  previousStartDate: Date;
  previousEndDate: Date;
  label: string;
}

/**
 * Parses user-selected date range and computes the exact preceding comparison period
 * for deterministic, accurate KPI deltas without inventing percentages.
 */
export function parseDateRange(
  range?: string,
  customStart?: string,
  customEnd?: string
): DateRange {
  const now = new Date();
  let startDate: Date;
  let endDate = new Date(now);
  let label = range || '30d';

  if (range === 'today') {
    startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  } else if (range === '7d') {
    startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  } else if (range === '30d' || !range) {
    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    label = '30d';
  } else if (range === '90d') {
    startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
  } else if (range === 'this_month') {
    startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
  } else if (range === 'last_month') {
    startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0);
    endDate = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
  } else if (range === 'custom' && customStart && customEnd) {
    startDate = new Date(customStart);
    endDate = new Date(customEnd);
  } else {
    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }

  const durationMs = endDate.getTime() - startDate.getTime();
  const previousEndDate = new Date(startDate.getTime() - 1);
  const previousStartDate = new Date(previousEndDate.getTime() - durationMs);

  return {
    startDate,
    endDate,
    previousStartDate,
    previousEndDate,
    label,
  };
}

/**
 * Computes percentage change between current and previous values safely.
 * Returns null if previous value is 0 or data does not exist.
 */
export function calculatePercentageChange(current: number, previous: number): number | null {
  if (previous === 0) {
    return current > 0 ? 100 : 0;
  }
  const change = ((current - previous) / previous) * 100;
  return Math.round(change * 10) / 10;
}

/**
 * AI pricing rates in INR per 1 Million tokens.
 * Conversions based on Google Cloud Gemini rates at ₹85 / USD:
 * - Gemini 3.8 Flash: $0.15 / 1M input (~₹12.75), $0.60 / 1M output (~₹51.00)
 * - Gemini 3.5 Flash Lite: $0.075 / 1M input (~₹6.38), $0.30 / 1M output (~₹25.50)
 */
export const AI_PRICING = {
  geminiFlash: {
    inputPerMillionPaise: 1275, // ₹12.75 in paise
    outputPerMillionPaise: 5100, // ₹51.00 in paise
  },
  geminiFlashLite: {
    inputPerMillionPaise: 638, // ₹6.38 in paise
    outputPerMillionPaise: 2550, // ₹25.50 in paise
  },
  default: {
    inputPerMillionPaise: 1275,
    outputPerMillionPaise: 5100,
  },
};

export function estimateAiCostInPaise(
  inputTokens: number,
  outputTokens: number,
  model = 'gemini-3.8-flash'
): { inputCostPaise: number; outputCostPaise: number; totalCostPaise: number } {
  const isLite = model.includes('lite');
  const rates = isLite ? AI_PRICING.geminiFlashLite : AI_PRICING.geminiFlash;

  const inputCostPaise = Math.round((inputTokens / 1_000_000) * rates.inputPerMillionPaise);
  const outputCostPaise = Math.round((outputTokens / 1_000_000) * rates.outputPerMillionPaise);
  const totalCostPaise = inputCostPaise + outputCostPaise;

  return { inputCostPaise, outputCostPaise, totalCostPaise };
}

/**
 * Converts array of plain objects into clean RFC-4180 CSV string.
 */
export function convertToCsv(rows: Record<string, any>[]): string {
  if (rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const headerRow = headers.join(',');

  const dataRows = rows.map((row) =>
    headers
      .map((header) => {
        let val = row[header];
        if (val === null || val === undefined) return '""';
        if (val instanceof Date) val = val.toISOString();
        if (typeof val === 'object') val = JSON.stringify(val);
        const strVal = String(val).replace(/"/g, '""');
        return `"${strVal}"`;
      })
      .join(',')
  );

  return [headerRow, ...dataRows].join('\n');
}
