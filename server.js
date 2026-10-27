const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');

const app = express();
app.use(helmet());
app.use(cors({
    origin: '*', // ALLOWS YOUR CHROME EXTENSION TO TALK TO THE API
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-api-key']
}));
app.use(express.json());

const apiKeys = {
    'sk_test_demo': { tier: 'free', limit: 1000, used: 0 }
};

function authenticateKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    const client = apiKeys[apiKey];
    if (!client) return res.status(403).json({ error: 'Invalid API Key' });
    if (client.used >= client.limit) return res.status(429).json({ error: 'Quota exceeded' });
    client.used += 1;
    req.client = client;
    next();
}

app.post('/v1/redact', authenticateKey, async (req, res) => {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: 'Missing text' });

    try {
        const PYTHON_API_URL = process.env.PYTHON_API_URL || 'http://127.0.0.1:5001/analyze';
        const aiResponse = await axios.post(PYTHON_API_URL, { text: text });
        
        const { redacted_text, entities_found } = aiResponse.data;

        res.json({
            status: 'success',
            redacted_text: redacted_text,
            entities_found: entities_found,
            requests_remaining: req.client.limit - req.client.used
        });

    } catch (error) {
        console.error("Python API Error:", error.message);
        res.status(500).json({ error: 'AI Service unavailable' });
    }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`API Gateway running on port ${PORT}`));