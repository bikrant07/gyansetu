// Chat endpoint
app.post('/api/chat', async (req, res) => {
    try {
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
}); 