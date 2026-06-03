const axios = require('axios');

exports.chat = async (messages) => {
  return exports.chatWithContext(messages, '');
};

exports.chatWithContext = async (messages, context) => {
  const systemPrompt = `Kamu adalah Finpals AI, asisten keuangan personal yang cerdas dan ramah.
Kamu membantu pengguna mengelola keuangan, memberikan tips hemat, analisis pengeluaran, dan saran budgeting.
Jawab dalam Bahasa Indonesia yang santai dan mudah dipahami.
${context ? `\n${context}` : ''}`;

  const response = await axios.post(
    'https://api.groq.com/openai/v1/chat/completions',
    {
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: systemPrompt },
        ...messages,
      ],
      max_tokens: 1024,
      temperature: 0.7,
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
    }
  );

  return response.data.choices[0].message.content;
};