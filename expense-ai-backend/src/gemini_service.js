
const API_BASE =
  'https://generativelanguage.googleapis.com/v1beta/models';

export async function analyzeExpenses(data) {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';

  if (!apiKey) {
    throw new Error('SERVER_MISSING_API_KEY');
  }

  const prompt = `
Bạn là trợ lý quản lý chi tiêu cá nhân, trả lời bằng tiếng Việt.

Phân tích dữ liệu tài chính đã tổng hợp dưới đây.
Không tự tạo giao dịch hoặc thu nhập không có trong dữ liệu.
Đánh giá mức chi tiêu dựa trên ngân sách do người dùng đặt.
Nếu dữ liệu chưa đủ, phải nói rõ giới hạn.
Không tư vấn đầu tư hoặc vay nợ.
Đề xuất thực tế, có thể thực hiện, không phán xét người dùng.

Dữ liệu:
${JSON.stringify(data)}
`;

  const response = await fetch(
    `${API_BASE}/${model}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: {
            type: 'OBJECT',
            properties: {
              status: {
                type: 'STRING',
                enum: ['good', 'warning', 'high', 'insufficient_data'],
              },
              summary: { type: 'STRING' },
              insights: {
                type: 'ARRAY',
                items: { type: 'STRING' },
              },
              recommendations: {
                type: 'ARRAY',
                items: {
                  type: 'OBJECT',
                  properties: {
                    title: { type: 'STRING' },
                    detail: { type: 'STRING' },
                    weeklyLimit: { type: 'NUMBER' },
                  },
                  required: ['title', 'detail', 'weeklyLimit'],
                },
              },
              weeklyPlan: {
                type: 'OBJECT',
                properties: {
                  recommendedWeeklyLimit: { type: 'NUMBER' },
                  reason: { type: 'STRING' },
                },
                required: ['recommendedWeeklyLimit', 'reason'],
              },
              disclaimer: { type: 'STRING' },
            },
            required: [
              'status',
              'summary',
              'insights',
              'recommendations',
              'weeklyPlan',
              'disclaimer',
            ],
          },
        },
      }),
      signal: AbortSignal.timeout(45000),
    },
  );

  if (!response.ok) {
    const detail = await response.text();
    console.error('Gemini API error:', response.status, detail);

    if (response.status === 429) {
      throw new Error('GEMINI_RATE_LIMIT');
    }

    if (response.status === 400 || response.status === 404) {
      throw new Error('GEMINI_CONFIGURATION_ERROR');
    }

    if (response.status === 401 || response.status === 403) {
      throw new Error('GEMINI_AUTH_ERROR');
    }

    throw new Error('GEMINI_UPSTREAM_ERROR');
  }

  const result = await response.json();
  const output = result.candidates?.[0]?.content?.parts
    ?.map((part) => part.text || '')
    .join('');

  if (!output) {
    throw new Error('GEMINI_EMPTY_RESPONSE');
  }

  let parsed;

  try {
    parsed = JSON.parse(output);
  } catch {
    throw new Error('GEMINI_INVALID_JSON');
  }

  if (
    typeof parsed.summary !== 'string' ||
    !Array.isArray(parsed.insights) ||
    !Array.isArray(parsed.recommendations) ||
    !parsed.weeklyPlan
  ) {
    throw new Error('GEMINI_INVALID_RESULT');
  }

  return parsed;
}
