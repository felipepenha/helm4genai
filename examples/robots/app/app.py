"""Robots.txt Fetcher Agent Application.

This module defines a Gradio-based web application that acts as a frontend
for fetching and displaying 'robots.txt' files from specified URLs.
It communicates with a backend MCP server to perform the actual fetching.
"""

import os
import re

import gradio as gr
import requests

MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://localhost:8080")


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

    try:
        # Call MCP Server
        # We assume the MCP server exposes a simple /fetch endpoint for this demo
        response = requests.get(
            f"{MCP_SERVER_URL}/fetch", params={"url": url.rstrip("/") + "/robots.txt"}, timeout=10
        )
        response.raise_for_status()
        return response.text
    except Exception as e:
        return f"Error fetching robots.txt: {str(e)}"


with gr.Blocks() as demo:
    gr.Markdown("# Robots.txt Fetcher Agent")

    url_input = gr.Textbox(
        label="Enter Website URL",
        placeholder="https://www.nytimes.com/",
    )
    output = gr.TextArea(label="Robots.txt Content")
    fetch_btn = gr.Button("Fetch Robots.txt")

    fetch_btn.click(fn=fetch_robots_txt, inputs=url_input, outputs=output)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
