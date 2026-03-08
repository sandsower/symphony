import gleeunit/should
import rondo/config

pub fn default_config_has_expected_values_test() {
  let c = config.default()
  c.tracker_kind |> should.equal("linear")
  c.poll_interval_ms |> should.equal(30_000)
  c.max_concurrent_agents |> should.equal(2)
  c.claude_max_turns |> should.equal(3)
}

pub fn validate_fails_when_linear_token_missing_test() {
  let c = config.default()
  config.validate(c) |> should.equal(Error(config.MissingRequired("LINEAR_API_KEY")))
}

pub fn validate_passes_when_linear_token_set_test() {
  let c = config.Config(..config.default(), linear_api_token: "tok_test")
  config.validate(c) |> should.equal(Ok(c))
}
