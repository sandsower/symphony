import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import rondo/claude/event.{
  type ClaudeEvent, type TokenUsage, AssistantMessage, RateLimitEvent,
  ResultEvent, SessionStarted, SystemEvent, ToolResult, ToolUse, TokenUsage,
  Unknown,
}

pub type ParseError {
  InvalidJson(String)
  EmptyLine
}

pub fn parse_line(line: String) -> Result(ClaudeEvent, ParseError) {
  case string.trim(line) {
    "" -> Error(EmptyLine)
    trimmed -> {
      case json.parse(trimmed, decode.dynamic) {
        Error(_) -> Error(InvalidJson(trimmed))
        Ok(dyn) -> Ok(classify_event(trimmed, dyn))
      }
    }
  }
}

pub fn parse_lines(input: String) -> List(ClaudeEvent) {
  input
  |> string.split("\n")
  |> list.filter_map(parse_line)
}

fn classify_event(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let type_decoder = decode.at(["type"], decode.string)
  case decode.run(dyn, type_decoder) {
    Error(_) -> Unknown(raw: raw)
    Ok(event_type) ->
      case event_type {
        "system" -> decode_system_event(raw, dyn)
        "assistant" -> decode_assistant_event(raw, dyn)
        "tool_result" -> decode_tool_result(raw, dyn)
        "result" -> decode_result_event(raw, dyn)
        "rate_limit" -> decode_rate_limit(raw, dyn)
        _ -> Unknown(raw: raw)
      }
  }
}

fn decode_system_event(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let subtype_decoder = decode.at(["subtype"], decode.string)
  case decode.run(dyn, subtype_decoder) {
    Ok("init") -> {
      let sid_decoder = decode.at(["session_id"], decode.string)
      case decode.run(dyn, sid_decoder) {
        Ok(sid) -> SessionStarted(session_id: sid)
        Error(_) -> Unknown(raw: raw)
      }
    }
    _ -> {
      let msg_decoder = decode.at(["message"], decode.string)
      case decode.run(dyn, msg_decoder) {
        Ok(msg) -> SystemEvent(message: msg)
        Error(_) -> Unknown(raw: raw)
      }
    }
  }
}

fn decode_assistant_event(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let content_type_decoder =
    decode.at(["message", "content"], decode.list(decode.dynamic))
  case decode.run(dyn, content_type_decoder) {
    Ok(content_items) -> {
      case list.first(content_items) {
        Ok(first_item) -> {
          let item_type_decoder = decode.at(["type"], decode.string)
          case decode.run(first_item, item_type_decoder) {
            Ok("tool_use") -> decode_tool_use(raw, first_item)
            _ -> decode_text_message(raw, dyn, first_item)
          }
        }
        Error(_) -> Unknown(raw: raw)
      }
    }
    Error(_) -> Unknown(raw: raw)
  }
}

fn decode_tool_use(raw: String, item: decode.Dynamic) -> ClaudeEvent {
  let name_decoder = decode.at(["name"], decode.string)
  let input_decoder = decode.at(["input"], decode.string)
  case decode.run(item, name_decoder), decode.run(item, input_decoder) {
    Ok(name), Ok(input) -> ToolUse(name: name, input: input)
    _, _ -> Unknown(raw: raw)
  }
}

fn decode_text_message(
  raw: String,
  dyn: decode.Dynamic,
  first_item: decode.Dynamic,
) -> ClaudeEvent {
  let text_decoder = decode.at(["text"], decode.string)
  case decode.run(first_item, text_decoder) {
    Ok(text) -> {
      let usage = decode_usage(dyn)
      AssistantMessage(content: text, usage: usage)
    }
    Error(_) -> Unknown(raw: raw)
  }
}

fn decode_tool_result(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let content_decoder = decode.at(["content"], decode.string)
  let error_decoder = decode.at(["is_error"], decode.bool)
  case decode.run(dyn, content_decoder) {
    Ok(content) -> {
      let is_error = decode.run(dyn, error_decoder) |> result.unwrap(False)
      ToolResult(output: content, is_error: is_error)
    }
    Error(_) -> Unknown(raw: raw)
  }
}

fn decode_result_event(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let result_decoder = decode.at(["result"], decode.string)
  let sid_decoder = decode.at(["session_id"], decode.string)
  case decode.run(dyn, result_decoder), decode.run(dyn, sid_decoder) {
    Ok(res), Ok(sid) ->
      ResultEvent(result: res, session_id: sid, usage: decode_usage(dyn))
    _, _ -> Unknown(raw: raw)
  }
}

fn decode_rate_limit(raw: String, dyn: decode.Dynamic) -> ClaudeEvent {
  let retry_decoder = decode.at(["retry_after"], decode.int)
  case decode.run(dyn, retry_decoder) {
    Ok(retry) -> RateLimitEvent(retry_after: retry)
    Error(_) -> Unknown(raw: raw)
  }
}

fn decode_usage(dyn: decode.Dynamic) -> TokenUsage {
  let input_decoder = decode.at(["usage", "input_tokens"], decode.int)
  let output_decoder = decode.at(["usage", "output_tokens"], decode.int)
  let input = decode.run(dyn, input_decoder) |> result.unwrap(0)
  let output = decode.run(dyn, output_decoder) |> result.unwrap(0)
  TokenUsage(input_tokens: input, output_tokens: output, total_tokens: input + output)
}
