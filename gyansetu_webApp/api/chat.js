import { OpenAI } from 'openai';

export default async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        const openai = new OpenAI({
            apiKey: process.env.OPENAI_API_KEY
        });

        const { message, context } = req.body;

        const messages = [
            {
                role: 'system',
                content: `You are a helpful AI assistant for GyanSetu, an educational platform. 
                         Your goal is to provide clear, accurate, and educational responses 
                         while maintaining a friendly and encouraging tone. Focus on explaining 
                         concepts in simple terms and encourage further learning.`
            },
            ...(context || []).map(msg => ({
                role: msg.role,
                content: msg.content
            })),
            {
                role: 'user',
                content: message
            }
        ];

        const completion = await openai.chat.completions.create({
            model: 'gpt-4',
            messages,
            temperature: 0.7,
            max_tokens: 500,
            presence_penalty: 0.6
        });

        res.json({
            response: completion.choices[0].message.content,
            status: 'success'
        });
    } catch (error) {
        console.error('OpenAI API error:', error);
        res.status(500).json({ 
            error: 'An error occurred while processing your request',
            details: error.message
        });
    }
} 