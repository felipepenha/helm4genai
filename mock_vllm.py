from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    # Mock response mimicking vLLM/OpenAI
    return jsonify({
        "id": "mock-vllm-response",
        "object": "chat.completion",
        "created": 1234567890,
        "model": "facebook/opt-125m",
        "choices": [{
            "index": 0,
            "message": {
                "role": "assistant",
                "content": """# 🤖 Robots.txt Analysis (MOCK vLLM)

| Category | Statistic / Count | Insight |
| :--- | :--- | :--- |
| **Total Directives** | **42** | MOCK: High granularity detected. |
| **User-agents** | **15** | MOCK: Specific bot targeting. |
| **Disallows** | **30** | MOCK: Restrictive policy. |
| **Sitemaps** | **2** | MOCK: Standard discovery. |
| **---** | **---** | **---** |
| **LLM Block Status** | | **Aggressive Blocking (Mock)** |
| **Total AI Bots** | **5** | MOCK: Key AI labs blocked. |
| **OpenAI** | `GPTBot` | MOCK: Training denied. |
| **Anthropic** | `ClaudeBot` | MOCK: Crawling denied. |
"""
            },
            "finish_reason": "stop"
        }],
        "usage": {
            "prompt_tokens": 100,
            "completion_tokens": 50,
            "total_tokens": 150
        }
    })

@app.route("/v1/models", methods=["GET"])
def models():
     return jsonify({
         "object": "list",
         "data": [{"id": "facebook/opt-125m", "object": "model", "created": 1234567890, "owned_by": "mock"}]
     })

if __name__ == "__main__":
    import sys
    print(f"Starting mock vLLM with args: {sys.argv[1:]}")
    app.run(host="0.0.0.0", port=8000)
