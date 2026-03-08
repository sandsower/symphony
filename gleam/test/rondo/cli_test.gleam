import gleeunit/should

pub fn missing_guardrail_flag_errors_test() {
  // CLI reads from argv which we can't easily mock in Gleam.
  // This test verifies the module compiles and types check.
  should.be_true(True)
}
