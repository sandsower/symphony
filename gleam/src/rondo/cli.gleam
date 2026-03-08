import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rondo/config

pub type CliError {
  MissingGuardrailFlag
  ConfigError(config.ConfigError)
}

pub fn run() -> Result(Nil, CliError) {
  let args = argv.load().arguments

  case
    list.contains(
      args,
      "--i_understand_that_this_will_be_running_without_the_usual_guardrails",
    )
  {
    False -> {
      io.println(
        "Error: You must pass --i_understand_that_this_will_be_running_without_the_usual_guardrails",
      )
      Error(MissingGuardrailFlag)
    }
    True -> {
      let _workflow_path = find_positional_arg(args)
      let cfg = config.from_env()
      case config.validate(cfg) {
        Error(e) -> {
          io.println("Config validation failed: " <> string.inspect(e))
          Error(ConfigError(e))
        }
        Ok(_config) -> {
          io.println("Rondo starting...")
          // In full implementation: start supervisor tree, orchestrator, dashboard, HTTP
          Ok(Nil)
        }
      }
    }
  }
}

fn find_positional_arg(args: List(String)) -> String {
  args
  |> list.filter(fn(a) { !string.starts_with(a, "--") })
  |> list.first()
  |> result.unwrap("WORKFLOW.md")
}
