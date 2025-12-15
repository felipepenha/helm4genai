"""Robots.txt Fetcher Agent Application.

This module defines a Gradio-based web application that acts as a frontend
for fetching and displaying 'robots.txt' files from specified URLs.
It communicates with a backend MCP server to perform the actual fetching.
"""

import os
import re
import sys

# Ensure `app` package is in path if needed for imports
# Since we are running `app.py` as a script, `baml_client` is a subdirectory.
# The `baml_client` folder contains `baml_client` package.
# So we import from `baml_client.baml_client`.
try:
    from baml_client.baml_client import b
    from baml_client.baml_client.types import RobotsSummary
except ImportError:
    # Fallback if running from a different context
    sys.path.append(os.path.join(os.path.dirname(__file__), "baml_client"))
    from baml_client import b  # type: ignore
    from baml_client.types import RobotsSummary  # type: ignore

import gradio as gr
import requests

MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://localhost:8080")

# Set default environment variables for BAML if not present
if "VLLM_API_URL" not in os.environ:
    os.environ["VLLM_API_URL"] = "http://vllm.genai.svc.cluster.local:8000/v1"
if "VLLM_API_KEY" not in os.environ:
    os.environ["VLLM_API_KEY"] = "EMPTY"


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

    fetch_mode = os.getenv("FETCH_MODE", "mcp")

    try:
        if fetch_mode == "direct":
            # Direct Fetch Mode (No MCP)
            headers = {"User-Agent": "RobotsAgent/1.0 (LocalTest)"}
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            return response.text
        else:
            # MCP Server Mode (Default)
            response = requests.get(f"{MCP_SERVER_URL}/fetch", params={"url": url})
            response.raise_for_status()
            return response.text
    except Exception as e:
        return f"Error fetching robots.txt: {str(e)}"


def format_analysis_to_markdown(analysis: RobotsSummary, url: str) -> str:
    """Formats the BAML analysis object into the requested Markdown table."""
    md = "## 🤖 Robots.txt AI Analysis Summary\n\n"
    md += f"**Policy Summary:** {analysis.policy_summary}\n\n"

    md += "| Agent Category | Status | Details |\n"
    md += "| :--- | :--- | :--- |\n"

    def format_status(status):
        if status == "Allowed":
            return "✅ Allowed"
        elif status == "Blocked":
            return "🚫 Blocked"
        elif status == "Partial":
            return "⚠️ Partial"
        return "❓ Unknown"

    md += f"| **GPTBot (OpenAI)** | {format_status(analysis.gptbot_status)} | Crawler for ChatGPT/GPT-4 |\n"
    md += f"| **ClaudeBot (Anthropic)** | {format_status(analysis.claude_status)} | Crawler for Claude models |\n"
    md += f"| **CCBot (CommonCrawl)** | {format_status(analysis.ccbot_status)} | Dataset used by many LLMs |\n"
    md += f"| **Googlebot** | {format_status(analysis.google_status)} | Primary Google Search crawler |\n"

    return md


async def analyze_robots_txt(url):
    """Fetches robots.txt and analyzes it using BAML."""
    robots_content = fetch_robots_txt(url)

    if robots_content.startswith("Error"):
        return robots_content, "Analysis cannot be performed due to fetch error."

    try:
        # BAML Analysis
        analysis = await b.AnalyzeRobotsTxt(robots_content)
        md_report = format_analysis_to_markdown(analysis, url)
        return robots_content, md_report

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
        analysis_output = gr.Markdown(label="AI Analysis (BAML)")

    fetch_btn.click(
        fn=analyze_robots_txt,
        inputs=url_input,
        outputs=[robots_output, analysis_output],
    )

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
