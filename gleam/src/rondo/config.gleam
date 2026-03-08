import envoy
import gleam/int
import gleam/result
import gleam/string

pub type Config {
  Config(
    // Tracker
    tracker_kind: String,
    linear_endpoint: String,
    linear_api_token: String,
    linear_project_slug: String,
    linear_assignee: String,
    linear_active_states: List(String),
    linear_terminal_states: List(String),
    label_filter: List(String),
    // Polling
    poll_interval_ms: Int,
    max_concurrent_agents: Int,
    max_retry_backoff_ms: Int,
    // Workspace
    workspace_root: String,
    workspace_hooks: WorkspaceHooks,
    // Claude
    claude_command: String,
    claude_turn_timeout_ms: Int,
    claude_stall_timeout_ms: Int,
    claude_permission_mode: String,
    claude_dangerously_skip_permissions: Bool,
    claude_max_turns: Int,
    claude_output_format: String,
    claude_model: String,
    claude_allowed_tools: List(String),
    // Prompt
    workflow_prompt: String,
    // Observability
    observability_enabled: Bool,
    observability_refresh_ms: Int,
    observability_render_interval_ms: Int,
    // Server
    server_port: Int,
    server_host: String,
  )
}

pub type WorkspaceHooks {
  WorkspaceHooks(
    after_create: String,
    before_run: String,
    after_run: String,
    before_remove: String,
    timeout_ms: Int,
  )
}

pub fn default() -> Config {
  Config(
    tracker_kind: "linear",
    linear_endpoint: "https://api.linear.app/graphql",
    linear_api_token: "",
    linear_project_slug: "",
    linear_assignee: "",
    linear_active_states: ["Todo", "In Progress"],
    linear_terminal_states: ["Done", "Cancelled"],
    label_filter: [],
    poll_interval_ms: 30_000,
    max_concurrent_agents: 2,
    max_retry_backoff_ms: 300_000,
    workspace_root: "/tmp/rondo-workspaces",
    workspace_hooks: WorkspaceHooks(
      after_create: "",
      before_run: "",
      after_run: "",
      before_remove: "",
      timeout_ms: 60_000,
    ),
    claude_command: "claude",
    claude_turn_timeout_ms: 1_800_000,
    claude_stall_timeout_ms: 300_000,
    claude_permission_mode: "default",
    claude_dangerously_skip_permissions: False,
    claude_max_turns: 3,
    claude_output_format: "stream-json",
    claude_model: "",
    claude_allowed_tools: [],
    workflow_prompt: "",
    observability_enabled: True,
    observability_refresh_ms: 1000,
    observability_render_interval_ms: 16,
    server_port: 0,
    server_host: "127.0.0.1",
  )
}

pub fn from_env() -> Config {
  let d = default()
  Config(
    ..d,
    tracker_kind: env_or("RONDO_TRACKER", d.tracker_kind),
    linear_endpoint: env_or("LINEAR_ENDPOINT", d.linear_endpoint),
    linear_api_token: env_or("LINEAR_API_KEY", d.linear_api_token),
    linear_project_slug: env_or("LINEAR_PROJECT_SLUG", d.linear_project_slug),
    linear_assignee: env_or("LINEAR_ASSIGNEE", d.linear_assignee),
    poll_interval_ms: env_int_or("RONDO_POLL_INTERVAL_MS", d.poll_interval_ms),
    max_concurrent_agents: env_int_or("RONDO_MAX_CONCURRENT", d.max_concurrent_agents),
    workspace_root: env_or("RONDO_WORKSPACE_ROOT", d.workspace_root),
    claude_command: env_or("CLAUDE_COMMAND", d.claude_command),
    claude_max_turns: env_int_or("CLAUDE_MAX_TURNS", d.claude_max_turns),
    claude_model: env_or("CLAUDE_MODEL", d.claude_model),
    claude_dangerously_skip_permissions: env_bool_or("CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS", d.claude_dangerously_skip_permissions),
    server_port: env_int_or("RONDO_SERVER_PORT", d.server_port),
    server_host: env_or("RONDO_SERVER_HOST", d.server_host),
  )
}

pub type ConfigError {
  MissingRequired(field: String)
}

pub fn validate(config: Config) -> Result(Config, ConfigError) {
  case config.tracker_kind {
    "linear" ->
      case string.is_empty(config.linear_api_token) {
        True -> Error(MissingRequired("LINEAR_API_KEY"))
        False -> Ok(config)
      }
    _ -> Ok(config)
  }
}

fn env_or(key: String, fallback: String) -> String {
  envoy.get(key) |> result.unwrap(fallback)
}

fn env_int_or(key: String, fallback: Int) -> Int {
  case envoy.get(key) {
    Ok(val) -> int.parse(val) |> result.unwrap(fallback)
    Error(_) -> fallback
  }
}

fn env_bool_or(key: String, fallback: Bool) -> Bool {
  case envoy.get(key) {
    Ok("true") | Ok("1") -> True
    Ok("false") | Ok("0") -> False
    _ -> fallback
  }
}
