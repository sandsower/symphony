import gleam/bytes_tree
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/set
import mist.{type Connection, type ResponseData}
import rondo/orchestrator.{type OrchestratorMessage, type Snapshot}

pub fn start(
  orchestrator: Subject(OrchestratorMessage),
  port: Int,
) -> Result(Nil, String) {
  let handler = fn(req: Request(Connection)) {
    handle_request(req, orchestrator)
  }

  let assert Ok(_) =
    mist.new(handler)
    |> mist.port(port)
    |> mist.start_http()

  Ok(Nil)
}

fn handle_request(
  req: Request(Connection),
  orchestrator: Subject(OrchestratorMessage),
) -> Response(ResponseData) {
  case req.method, request.path_segments(req) {
    http.Get, [] -> health_response()
    http.Get, ["api", "v1", "state"] -> state_response(orchestrator)
    http.Post, ["api", "v1", "refresh"] -> refresh_response(orchestrator)
    _, _ -> not_found_response()
  }
}

fn health_response() -> Response(ResponseData) {
  let body =
    json.object([#("status", json.string("ok"))]) |> json.to_string()
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn state_response(
  orchestrator: Subject(OrchestratorMessage),
) -> Response(ResponseData) {
  let snapshot_subject = process.new_subject()
  process.send(orchestrator, orchestrator.GetSnapshot(snapshot_subject))

  case process.receive(snapshot_subject, 5000) {
    Error(_) -> {
      let body =
        json.object([#("error", json.string("timeout"))]) |> json.to_string()
      response.new(503)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
    }
    Ok(snapshot) -> {
      let body = snapshot_to_json(snapshot)
      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
    }
  }
}

fn refresh_response(
  orchestrator: Subject(OrchestratorMessage),
) -> Response(ResponseData) {
  process.send(orchestrator, orchestrator.RequestRefresh)
  let body =
    json.object([#("status", json.string("accepted"))]) |> json.to_string()
  response.new(202)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn not_found_response() -> Response(ResponseData) {
  let body =
    json.object([#("error", json.string("not found"))]) |> json.to_string()
  response.new(404)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn snapshot_to_json(snapshot: Snapshot) -> String {
  let running_count = dict.size(snapshot.running)
  let completed_count = set.size(snapshot.completed)
  json.object([
    #("running_count", json.int(running_count)),
    #("completed_count", json.int(completed_count)),
    #("totals", json.object([
      #("input_tokens", json.int(snapshot.totals.input_tokens)),
      #("output_tokens", json.int(snapshot.totals.output_tokens)),
      #("total_tokens", json.int(snapshot.totals.total_tokens)),
    ])),
  ])
  |> json.to_string()
}
