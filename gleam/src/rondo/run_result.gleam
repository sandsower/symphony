import rondo/claude/event.{type TokenUsage}

pub type RunResult {
  Completed(session_id: String, usage: TokenUsage)
  Failed(reason: RunFailure)
  TimedOut(session_id: String, elapsed_ms: Int)
}

pub type RunFailure {
  ProcessCrashed(exit_code: Int)
  ParseError(raw: String)
  RateLimited(retry_after: Int)
  WorkspaceError(detail: String)
  TrackerError(detail: String)
}
