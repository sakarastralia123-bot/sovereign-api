# Nepali AI Privacy Gateway (PII Redaction API)

A security firewall API designed to protect sensitive data before it is sent to Large Language Models (LLMs) like OpenAI, ChatGPT, or DeepSeek.

Built specifically for the Nepali market, this API automatically detects and redacts:
- **Person Names** (using Contextual NLP)
- **Passwords & API Keys**
- **Nepali Phone Numbers** (NTC & Ncell formats)
- **Citizen IDs** (10-digit formats)
- **Emails**
- **Credit Card Numbers**

## 🚀 How It Works

Instead of sending raw user data to a foreign AI model, your application routes the text through our API. The API scrubs the data locally using Microsoft Presidio (airgapped, no data leaves the server) and returns a safe string.
