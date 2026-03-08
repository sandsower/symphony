import gleeunit/should
import rondo/claude/event.{
  AssistantMessage, RateLimitEvent, ResultEvent, SessionStarted,
  SystemEvent, TokenUsage, ToolResult, ToolUse, Unknown,
}
import rondo/claude/stream

pub fn parse_system_init_event_test() {
  let json =
    "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"sess-1\",\"message\":\"starting\"}"
  stream.parse_line(json)
  |> should.equal(Ok(SessionStarted(session_id: "sess-1")))
}

pub fn parse_assistant_message_test() {
  let json =
    "{\"type\":\"assistant\",\"message\":{\"content\":[{\"text\":\"hello\"}]},\"usage\":{\"input_tokens\":10,\"output_tokens\":5}}"
  stream.parse_line(json)
  |> should.equal(Ok(AssistantMessage(
    content: "hello",
    usage: TokenUsage(input_tokens: 10, output_tokens: 5, total_tokens: 15),
  )))
}

pub fn parse_tool_use_test() {
  let json =
    "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Read\",\"input\":\"{}\"}]}}"
  stream.parse_line(json)
  |> should.equal(Ok(ToolUse(name: "Read", input: "{}")))
}

pub fn parse_tool_result_test() {
  let json =
    "{\"type\":\"tool_result\",\"content\":\"file contents\",\"is_error\":false}"
  stream.parse_line(json)
  |> should.equal(Ok(ToolResult(output: "file contents", is_error: False)))
}

pub fn parse_result_event_test() {
  let json =
    "{\"type\":\"result\",\"result\":\"done\",\"session_id\":\"sess-1\",\"usage\":{\"input_tokens\":100,\"output_tokens\":50}}"
  stream.parse_line(json)
  |> should.equal(Ok(ResultEvent(
    result: "done",
    session_id: "sess-1",
    usage: TokenUsage(input_tokens: 100, output_tokens: 50, total_tokens: 150),
  )))
}

pub fn parse_rate_limit_test() {
  let json = "{\"type\":\"rate_limit\",\"retry_after\":30}"
  stream.parse_line(json)
  |> should.equal(Ok(RateLimitEvent(retry_after: 30)))
}

pub fn parse_other_system_event_test() {
  let json = "{\"type\":\"system\",\"message\":\"something\"}"
  stream.parse_line(json)
  |> should.equal(Ok(SystemEvent(message: "something")))
}

pub fn parse_unknown_type_test() {
  let json = "{\"type\":\"weird\",\"data\":1}"
  stream.parse_line(json)
  |> should.equal(Ok(Unknown(raw: json)))
}

pub fn parse_invalid_json_test() {
  stream.parse_line("not json")
  |> should.be_error()
}

pub fn parse_empty_line_test() {
  stream.parse_line("")
  |> should.be_error()
}

pub fn parse_lines_splits_and_parses_test() {
  let input =
    "{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"s1\",\"message\":\"hi\"}\n{\"type\":\"rate_limit\",\"retry_after\":5}"
  let events = stream.parse_lines(input)
  events
  |> should.equal([
    SessionStarted(session_id: "s1"),
    RateLimitEvent(retry_after: 5),
  ])
}
