generator my_client {
  output_type "python/pydantic"
  output_dir "../app/baml_client"
  version "0.214.0"
}

// Define a simple enum for access status
enum AccessStatus {
  Allowed
  Blocked
  Partial
  Unknown
}

// A flat, simple structure that easier for smaller models to generate
class RobotsSummary {
  // A short summary of the website's policy regarding AI/scraping
  policy_summary string
  
  // Specific status for key AI agents
  gptbot_status AccessStatus @description("Status for 'GPTBot' or OpenAI crawlers")
  claude_status AccessStatus @description("Status for 'ClaudeBot', 'anthropic-ai', or 'Claude'")
  ccbot_status AccessStatus @description("Status for 'CCBot' or 'CommonCrawl'")
  google_status AccessStatus @description("Status for 'Googlebot'")
}

// Custom client for local vLLM
client LocalLLMClient {
  provider openai
  options {
    base_url env.VLLM_API_URL
    api_key env.VLLM_API_KEY
    model "gpt-oss:20b"
    temperature 0.0
    // Preserving max_tokens from config.toml
    max_tokens 10000
  }
}

function AnalyzeRobotsTxt(content: string) -> RobotsSummary {
  client LocalLLMClient
  prompt #"
    {{ _.role('system') }}
    You are a helpful assistant that analyzes robots.txt files.
    Your job is to determine if specific AI bots are allowed or blocked.

    {{ _.role('user') }}
    Analyze the following robots.txt content:

    ---
    {{ content }}
    ---

    Determine the access status for the following bots based on these rules:
    - Blocked: Explicitly "Disallow: /" or generally blocked.
    - Partial: Allowed to crawl but has specific "Disallow" paths (e.g. /private, /search).
    - Allowed: No "Disallow" rules found for this bot (or only trivial ones).
    - Unknown: Cannot determine status.

    Bots to Check:
    1. GPTBot (OpenAI)
    2. ClaudeBot (Anthropic)
    3. CCBot (Common Crawl)
    4. Googlebot

    Provide a short policy summary.

    {{ ctx.output_format }}
  "#
}