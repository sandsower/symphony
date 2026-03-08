import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import rondo/config.{type Config}
import rondo/issue.{type Issue}
import rondo/tracker.{type TrackerResult, ApiError}

pub fn fetch_candidate_issues(config: Config) -> TrackerResult(List(Issue)) {
  let query = case list.is_empty(config.label_filter) {
    True -> poll_query()
    False -> poll_with_labels_query()
  }
  let variables = build_poll_variables(config)
  case graphql(config, query, variables) {
    Error(e) -> Error(e)
    Ok(data) -> Ok(decode_issues(data))
  }
}

pub fn fetch_issue_states_by_ids(
  config: Config,
  ids: List(String),
) -> TrackerResult(List(Issue)) {
  let query = issues_by_id_query()
  let variables =
    json.object([#("ids", json.array(ids, json.string))])
    |> json.to_string()
  case graphql(config, query, variables) {
    Error(e) -> Error(e)
    Ok(data) -> Ok(decode_issues(data))
  }
}

pub fn create_comment(
  config: Config,
  issue_id: String,
  body: String,
) -> TrackerResult(Nil) {
  let query =
    "mutation RondoCreateComment($issueId: String!, $body: String!) { commentCreate(input: {issueId: $issueId, body: $body}) { success } }"
  let variables =
    json.object([
      #("issueId", json.string(issue_id)),
      #("body", json.string(body)),
    ])
    |> json.to_string()
  case graphql(config, query, variables) {
    Error(e) -> Error(e)
    Ok(_) -> Ok(Nil)
  }
}

pub fn update_issue_state(
  config: Config,
  issue_id: String,
  state_name: String,
) -> TrackerResult(Nil) {
  case resolve_state_id(config, issue_id, state_name) {
    Error(e) -> Error(e)
    Ok(state_id) -> {
      let query =
        "mutation RondoUpdateIssueState($issueId: String!, $stateId: String!) { issueUpdate(id: $issueId, input: {stateId: $stateId}) { success } }"
      let variables =
        json.object([
          #("issueId", json.string(issue_id)),
          #("stateId", json.string(state_id)),
        ])
        |> json.to_string()
      case graphql(config, query, variables) {
        Error(e) -> Error(e)
        Ok(_) -> Ok(Nil)
      }
    }
  }
}

fn resolve_state_id(
  config: Config,
  issue_id: String,
  state_name: String,
) -> TrackerResult(String) {
  let query =
    "query RondoResolveStateId($issueId: String!) { issue(id: $issueId) { team { states { nodes { id name } } } } }"
  let variables =
    json.object([#("issueId", json.string(issue_id))])
    |> json.to_string()
  case graphql(config, query, variables) {
    Error(e) -> Error(e)
    Ok(_data) -> {
      Error(ApiError(
        detail: "state resolution not yet implemented for " <> state_name,
      ))
    }
  }
}

fn graphql(
  config: Config,
  query: String,
  variables: String,
) -> TrackerResult(String) {
  let body =
    json.object([
      #("query", json.string(query)),
    ])
    |> json.to_string()
  // Inject variables as raw JSON
  let body =
    string.replace(body, "}", ", \"variables\": " <> variables <> "}")

  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host(extract_host(config.linear_endpoint))
    |> request.set_path(extract_path(config.linear_endpoint))
    |> request.set_header("content-type", "application/json")
    |> request.set_header("authorization", config.linear_api_token)
    |> request.set_body(body)
    |> request.set_scheme(http.Https)

  case httpc.send(req) {
    Error(_) -> Error(ApiError(detail: "HTTP request failed"))
    Ok(resp) ->
      case resp.status {
        200 -> Ok(resp.body)
        status ->
          Error(ApiError(
            detail: "Linear API returned status " <> int.to_string(status),
          ))
      }
  }
}

fn poll_query() -> String {
  "query RondoLinearPoll($projectSlug: String, $assigneeId: String, $states: [String!]) { issues(filter: {project: {slugId: {eq: $projectSlug}}, assignee: {id: {eq: $assigneeId}}, state: {name: {in: $states}}}, first: 50) { nodes { id identifier title description priority state { name } branchName url assignee { id } labels { nodes { name } } relations { nodes { relatedIssue { id identifier state { name } } type } } } } }"
}

fn poll_with_labels_query() -> String {
  "query RondoLinearPollWithLabels($projectSlug: String, $assigneeId: String, $states: [String!], $labels: [String!]) { issues(filter: {project: {slugId: {eq: $projectSlug}}, assignee: {id: {eq: $assigneeId}}, state: {name: {in: $states}}, labels: {name: {in: $labels}}}, first: 50) { nodes { id identifier title description priority state { name } branchName url assignee { id } labels { nodes { name } } relations { nodes { relatedIssue { id identifier state { name } } type } } } } }"
}

fn issues_by_id_query() -> String {
  "query RondoLinearIssuesById($ids: [ID!]!) { issues(filter: {id: {in: $ids}}) { nodes { id identifier title description priority state { name } branchName url assignee { id } labels { nodes { name } } } } }"
}

pub fn build_poll_variables(config: Config) -> String {
  let base = [
    #("projectSlug", json.string(config.linear_project_slug)),
    #("states", json.array(config.linear_active_states, json.string)),
  ]
  let base = case string.is_empty(config.linear_assignee) {
    True -> base
    False -> [#("assigneeId", json.string(config.linear_assignee)), ..base]
  }
  let base = case list.is_empty(config.label_filter) {
    True -> base
    False ->
      [#("labels", json.array(config.label_filter, json.string)), ..base]
  }
  json.object(base) |> json.to_string()
}

fn decode_issues(_data: String) -> List(Issue) {
  // Placeholder — full JSON decoding of Linear response into Issue list
  // will be implemented when wiring up end-to-end.
  []
}

fn extract_host(url: String) -> String {
  url
  |> string.replace("https://", "")
  |> string.replace("http://", "")
  |> string.split("/")
  |> list.first()
  |> result.unwrap("api.linear.app")
}

fn extract_path(url: String) -> String {
  let without_scheme =
    url
    |> string.replace("https://", "")
    |> string.replace("http://", "")
  case string.split_once(without_scheme, "/") {
    Ok(#(_, path)) -> "/" <> path
    Error(_) -> "/graphql"
  }
}
