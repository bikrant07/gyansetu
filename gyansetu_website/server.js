import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { OpenAI } from 'openai';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Configure CORS
app.use(cors({
    origin: '*', // Be more specific in production
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

app.use(express.json());
app.use(express.static('public'));

// Add OPTIONS handling
app.options('*', cors());

// Initialize OpenAI
const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
    try {
        if (!req.body.message) {
            return res.status(400).json({ 
                error: 'Message is required',
                status: 'error'
            });
        }

        const { message, context } = req.body;

        const messages = [
            {
                role: 'system',
                content: `You are a helpful AI assistant for GyanSetu, an educational platform. 
                         Your goal is to provide clear, accurate, and educational responses 
                         while maintaining a friendly and encouraging tone.`
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
            max_tokens: 500
        });

        res.json({
            response: completion.choices[0].message.content,
            status: 'success'
        });
    } catch (error) {
        console.error('OpenAI API error:', error);
        res.status(500).json({ 
            error: 'An error occurred',
            details: error.message,
            status: 'error'
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Something broke!',
        details: err.message,
        status: 'error'
    });
});

// Start server
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
}); 