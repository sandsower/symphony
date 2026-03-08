pub type ClaudeEvent {
  SessionStarted(session_id: String)
  AssistantMessage(content: String, usage: TokenUsage)
  ToolUse(name: String, input: String)
  ToolResult(output: String, is_error: Bool)
  ResultEvent(result: String, session_id: String, usage: TokenUsage)
  RateLimitEvent(retry_after: Int)
  SystemEvent(message: String)
  Unknown(raw: String)
}

pub type TokenUsage {
  TokenUsage(input_tokens: Int, output_tokens: Int, total_tokens: Int)
}

pub fn zero_usage() -> TokenUsage {
  TokenUsage(input_tokens: 0, output_tokens: 0, total_tokens: 0)
}

pub fn add_usage(a: TokenUsage, b: TokenUsage) -> TokenUsage {
  TokenUsage(
    input_tokens: a.input_tokens + b.input_tokens,
    output_tokens: a.output_tokens + b.output_tokens,
    total_tokens: a.total_tokens + b.total_tokens,
  )
}
