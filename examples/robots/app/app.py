"""Robots.txt Fetcher Agent Application.

This module defines a Gradio-based web application that acts as a frontend
for fetching and displaying 'robots.txt' files from specified URLs.
It communicates with a backend MCP server to perform the actual fetching.
"""

import os
import re

import gradio as gr
import requests
import tomli
from openai import OpenAI

MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://localhost:8080")
# vLLM Service URL (internal Kubernetes DNS)
VLLM_API_URL = os.getenv("VLLM_API_URL", "http://vllm.genai.svc.cluster.local:8000/v1")
VLLM_API_KEY = os.getenv("VLLM_API_KEY", "EMPTY") # vLLM usually doesn't require a key by default

# Load configuration
try:
    with open("config.toml", "rb") as f:
        config = tomli.load(f)
    MODEL_CONFIG = config.get("model", {})
    SYSTEM_PROMPT = MODEL_CONFIG.get("system_message", "")
except FileNotFoundError:
    print("Warning: config.toml not found. LLM features may be disabled.")
    MODEL_CONFIG = {}
    SYSTEM_PROMPT = ""

def fetch_robots_txt(url):
    """Fetches the robots.txt content from a given URL via the MCP server.

    Args:
        url: The base URL of the website to fetch `robots.txt` from.
             Must start with 'http://' or 'https://'.

    Returns:
        The content of the robots.txt file if successful, or an error message
        string if the URL is invalid or the fetch fails.
    """
    # Regex validation
    if not re.match(r"^https?://", url):
        return "Error: Invalid URL. Must start with http:// or https://"
    
    # Ensure URL ends with robots.txt
    if not url.endswith("/robots.txt"):
        url = url.rstrip("/") + "/robots.txt"

    try:
        # Call MCP Server
        # We assume the MCP server exposes a simple /fetch endpoint for this demo
        response = requests.get(f"{MCP_SERVER_URL}/fetch", params={"url": url})
        response.raise_for_status()
        return response.text
    except Exception as e:
        return f"Error fetching robots.txt: {str(e)}"

def analyze_robots_txt(url):
    """Fetches robots.txt and analyzes it using vLLM."""
    robots_content = fetch_robots_txt(url)
    
    if robots_content.startswith("Error"):
        return robots_content, "Analysis cannot be performed due to fetch error."

    if not SYSTEM_PROMPT:
         return robots_content, "Error: Configuration for LLM analysis (config.toml) is missing."

    try:
        client = OpenAI(
            base_url=VLLM_API_URL,
            api_key=VLLM_API_KEY,
        )
        
        # Prepare the conversation
        # Prepare the conversation
        messages = [{"role": "system", "content": MODEL_CONFIG.get("system_message", "")}]
        
        # Add few-shot examples if present
        example_user = MODEL_CONFIG.get("example_user", "")
        example_assistant = MODEL_CONFIG.get("example_assistant", "")
        
        if example_user and example_assistant:
            messages.append({"role": "user", "content": example_user})
            messages.append({"role": "assistant", "content": example_assistant})
            
        # Add actual user query
        messages.append({"role": "user", "content": robots_content})
        
        # Map specific models if needed, or use a default compatible with the deployed vLLM
        # config.toml says "gpt-oss:20b", but we might be running "facebook/opt-125m"
        # We'll rely on the deployed model or a generic alias if vLLM supports it.
        # Often vLLM uses the model name it launched with.
        # For simplicity in this demo, we'll try to fetch the model list or just use a placeholder
        # vLLM is permissive with model names in OpenAI API usually if only one is served.
        model_name = "facebook/opt-125m" # Default fallback
        try:
             models = client.models.list()
             if models.data:
                 model_name = models.data[0].id
        except Exception:
             print("Could not list models, using default.")

        completion = client.chat.completions.create(
            model=model_name,
            messages=messages,
            max_tokens=MODEL_CONFIG.get("max_tokens", 2048),
            temperature=MODEL_CONFIG.get("temperature", 0.1),
        )
        
        analysis = completion.choices[0].message.content
        return robots_content, analysis

    except Exception as e:
        return robots_content, f"Error performing AI analysis: {str(e)}"


with gr.Blocks() as demo:
    gr.Markdown("# Robots.txt Fetcher & Analyzer Agent")

    url_input = gr.Textbox(
        label="Enter Website URL",
        placeholder="https://www.nytimes.com/",
    )
    
    with gr.Row():
        fetch_btn = gr.Button("Analyze Robots.txt")
    
    with gr.Row():
        robots_output = gr.TextArea(label="Raw Robots.txt Content", lines=10)
        analysis_output = gr.Markdown(label="AI Analysis (vLLM)")

    fetch_btn.click(fn=analyze_robots_txt, inputs=url_input, outputs=[robots_output, analysis_output])

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
