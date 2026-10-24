
import 'dotenv/config';

import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { analyzeExpenses } from './gemini_service.js';

const app = express();
const port = Number(process.env.PORT) || 3000;

app.use(helmet());
app.use(express.json({ limit: '20kb' }));

app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'expense-ai-backend' });
});

app.post('/api/analyze', async (req, res) => {
  const data = req.body;

  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return res.status(400).json({ error: 'Body không hợp lệ.' });
  }

  const {
    month,
    monthlyIncome,
    monthlyBudget,
    savingGoal,
    totalSpent,
    transactionCount,
    categoryTotals,
  } = data;

  const amounts = [
    monthlyIncome,
    monthlyBudget,
    savingGoal,
    totalSpent,
    transactionCount,
  ];

  if (
    typeof month !== 'string' ||
    !/^\d{4}-(0[1-9]|1[0-2])$/.test(month) ||
    !amounts.every(
      (value) =>
        typeof value === 'number' &&
        Number.isFinite(value) &&
        value >= 0,
    ) ||
    !categoryTotals ||
    typeof categoryTotals !== 'object' ||
    Array.isArray(categoryTotals)
  ) {
    return res.status(400).json({
      error: 'Thiếu trường hoặc dữ liệu tài chính không hợp lệ.',
    });
  }

  const entries = Object.entries(categoryTotals);

  if (
    entries.length > 20 ||
    transactionCount > 10000 ||
    entries.some(
      ([name, amount]) =>
        name.length > 60 ||
        typeof amount !== 'number' ||
        !Number.isFinite(amount) ||
        amount < 0,
    )
  ) {
    return res.status(400).json({
      error: 'Dữ liệu danh mục hoặc số giao dịch không hợp lệ.',
    });
  }

  const safeData = {
    month,
    monthlyIncome,
    monthlyBudget,
    savingGoal,
    totalSpent,
    transactionCount: Math.floor(transactionCount),
    categoryTotals: Object.fromEntries(entries),
  };

  try {
    const analysis = await analyzeExpenses(safeData);

    return res.json({ success: true, analysis });
  } catch (error) {
    console.error('Analysis failed:', error.message);

    if (error.name === 'TimeoutError' || error.name === 'AbortError') {
      return res.status(504).json({
        error: 'AI phản hồi quá lâu. Vui lòng thử lại.',
      });
    }

    if (error.message === 'GEMINI_RATE_LIMIT') {
      return res.status(429).json({
        error: 'Gemini đang giới hạn yêu cầu. Hãy thử lại sau.',
      });
    }

    if (error.message === 'GEMINI_AUTH_ERROR') {
      return res.status(502).json({
        error: 'Backend chưa xác thực được với Gemini.',
      });
    }

    if (error.message === 'GEMINI_CONFIGURATION_ERROR') {
      return res.status(502).json({
        error: 'Cấu hình model hoặc request Gemini không hợp lệ.',
      });
    }

    return res.status(502).json({
      error: 'Không thể phân tích chi tiêu lúc này.',
    });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Expense AI backend đang chạy tại cổng ${port}`);
});
