import gleeunit/should
import rondo/claude/cli.{type CliOptions, CliOptions}

pub fn build_args_first_run_test() {
  let opts = test_opts()
  let args = cli.build_args("do the work", opts, "")
  args
  |> should.equal([
    "-p", "do the work",
    "--verbose",
    "--output-format", "stream-json",
    "--max-turns", "3",
    "--permission-mode", "default",
  ])
}

pub fn build_args_resume_test() {
  let opts = test_opts()
  let args = cli.build_args("continue", opts, "sess-1")
  // With resume: ["-p", "continue", "--resume", "sess-1", "--verbose", ...]
  args
  |> should.equal([
    "-p", "continue", "--resume", "sess-1",
    "--verbose",
    "--output-format", "stream-json",
    "--max-turns", "3",
    "--permission-mode", "default",
  ])
}

pub fn build_args_with_model_test() {
  let opts = CliOptions(..test_opts(), model: "opus")
  let args = cli.build_args("work", opts, "")
  let has_model = list_contains_pair(args, "--model", "opus")
  has_model |> should.equal(True)
}

pub fn build_args_with_skip_permissions_test() {
  let opts = CliOptions(..test_opts(), dangerously_skip_permissions: True)
  let args = cli.build_args("work", opts, "")
  let has_flag = list_contains(args, "--dangerously-skip-permissions")
  has_flag |> should.equal(True)
}

fn test_opts() -> CliOptions {
  CliOptions(
    command: "claude",
    output_format: "stream-json",
    max_turns: 3,
    permission_mode: "default",
    dangerously_skip_permissions: False,
    model: "",
    allowed_tools: [],
    turn_timeout_ms: 1_800_000,
  )
}

fn list_contains(lst: List(String), item: String) -> Bool {
  case lst {
    [] -> False
    [x, ..rest] ->
      case x == item {
        True -> True
        False -> list_contains(rest, item)
      }
  }
}

fn list_contains_pair(lst: List(String), key: String, val: String) -> Bool {
  case lst {
    [] -> False
    [k, v, ..rest] ->
      case k == key && v == val {
        True -> True
        False -> list_contains_pair([v, ..rest], key, val)
      }
    [_, ..] -> False
  }
}
