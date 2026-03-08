import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Workflow {
  Workflow(
    prompt_template: String,
    max_turns: Int,
    timeout_ms: Int,
    allowed_tools: List(String),
    raw_config: List(#(String, String)),
  )
}

pub type WorkflowError {
  FileNotFound(path: String)
  ReadError(detail: String)
}

pub fn load(path: String) -> Result(Workflow, WorkflowError) {
  case simplifile.read(path) {
    Ok(content) -> Ok(parse_content(content))
    Error(_) -> Error(FileNotFound(path: path))
  }
}

pub fn parse(content: String) -> Result(Workflow, Nil) {
  Ok(parse_content(content))
}

fn parse_content(content: String) -> Workflow {
  let trimmed = string.trim(content)
  case string.starts_with(trimmed, "---") {
    False ->
      Workflow(
        prompt_template: trimmed,
        max_turns: 0,
        timeout_ms: 0,
        allowed_tools: [],
        raw_config: [],
      )
    True -> {
      let after_first = string.drop_start(trimmed, 3)
      case string.split_once(after_first, "\n---") {
        Error(_) ->
          Workflow(
            prompt_template: trimmed,
            max_turns: 0,
            timeout_ms: 0,
            allowed_tools: [],
            raw_config: [],
          )
        Ok(#(frontmatter, body)) -> {
          let config = parse_frontmatter(string.trim(frontmatter))
          let prompt = string.trim(body)
          Workflow(
            prompt_template: prompt,
            max_turns: get_int_config(config, "max_turns", 0),
            timeout_ms: get_int_config(config, "timeout_ms", 0),
            allowed_tools: get_list_config(config, "allowed_tools"),
            raw_config: config,
          )
        }
      }
    }
  }
}

fn parse_frontmatter(text: String) -> List(#(String, String)) {
  let lines = string.split(text, "\n")
  parse_frontmatter_lines(lines, [])
}

fn parse_frontmatter_lines(
  lines: List(String),
  acc: List(#(String, String)),
) -> List(#(String, String)) {
  case lines {
    [] -> list.reverse(acc)
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case string.split_once(trimmed, ":") {
        Ok(#(key, value)) -> {
          let key = string.trim(key)
          let value = string.trim(value)
          case string.is_empty(value) {
            True -> {
              let #(items, remaining) = collect_list_items(rest, [])
              let list_value = string.join(items, ",")
              parse_frontmatter_lines(remaining, [#(key, list_value), ..acc])
            }
            False -> parse_frontmatter_lines(rest, [#(key, value), ..acc])
          }
        }
        Error(_) -> parse_frontmatter_lines(rest, acc)
      }
    }
  }
}

fn collect_list_items(
  lines: List(String),
  acc: List(String),
) -> #(List(String), List(String)) {
  case lines {
    [] -> #(list.reverse(acc), [])
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case string.starts_with(trimmed, "- ") {
        True -> {
          let item = string.drop_start(trimmed, 2) |> string.trim()
          collect_list_items(rest, [item, ..acc])
        }
        False -> #(list.reverse(acc), lines)
      }
    }
  }
}

fn get_int_config(
  config: List(#(String, String)),
  key: String,
  fallback: Int,
) -> Int {
  case list.find(config, fn(pair) { pair.0 == key }) {
    Ok(#(_, val)) -> int.parse(val) |> result.unwrap(fallback)
    Error(_) -> fallback
  }
}

fn get_list_config(
  config: List(#(String, String)),
  key: String,
) -> List(String) {
  case list.find(config, fn(pair) { pair.0 == key }) {
    Ok(#(_, val)) ->
      case string.is_empty(val) {
        True -> []
        False -> string.split(val, ",") |> list.map(string.trim)
      }
    Error(_) -> []
  }
}
