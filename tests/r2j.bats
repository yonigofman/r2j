#!/usr/bin/env bats

# Resolve repo root and PATH so tests work locally and in CI
setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  export PATH="$REPO_ROOT/bin:$PATH"
}

@test "shows help with -h and exits 0" {
  run r2j -h
  assert_success
  assert_line --partial "r2j v0.1.0"
  assert_line --partial "USAGE:"
}

@test "errors on unknown option and shows usage" {
  run r2j --wat
  assert_failure
  assert_line --partial "Unknown option"
  assert_line --partial "USAGE:"
}

@test "reads from stdin when no argument provided" {
  run bash -c 'echo "{:foo=>\"bar\"}" | r2j'
  assert_success
  assert_output '{"foo":"bar"}'
}

@test "reads from single-argument input" {
  run r2j "{:foo=>'bar',:num=>42}"
  assert_success
  assert_output '{"foo":"bar","num":42}'
}

@test "converts Ruby scalars: nil/true/false" {
  run r2j "{:a=>nil,:b=>true,:c=>false}"
  assert_success
  assert_output '{"a":null,"b":true,"c":false}'
}

@test "converts single-quoted strings to JSON double quotes" {
  run r2j "{:name=>'yoni',:lang=>'ruby'}"
  assert_success
  assert_output '{"name":"yoni","lang":"ruby"}'
}

@test "converts keys: symbols, string-keys, and :\"string\" syntax" {
  run r2j "{:sym=>'v', 'str' => 'x', :\"with space\"=>'y'}"
  assert_success
  assert_output '{"sym":"v","str":"x","with space":"y"}'
}

@test "converts symbol values to JSON strings" {
  run r2j "{:status=>:ok,:env=>:production}"
  assert_success
  assert_output '{"status":"ok","env":"production"}'
}

@test "replaces remaining hash rockets with colons" {
  run r2j "{'a'=>1, 'b'=>{'c'=>2}}"
  assert_success
  assert_output '{"a":1,"b":{"c":2}}'
}

@test "pretty output (-p) equals jq pretty formatting if jq is present" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not installed"
  fi

  input="{:foo=>'bar',:num=>[1,2,3],:\"weird key\"=>{:nested=>true}}"

  # Compact JSON
  run r2j "$input"
  assert_success
  compact="$output"

  # Pretty via tool
  run r2j -p "$input"
  assert_success
  pretty_tool="$output"

  # Normalize both through jq -c to compare structurally
  got_compact="$(printf '%s' "$compact" | jq -c .)"
  got_pretty_compact="$(printf '%s' "$pretty_tool" | jq -c .)"

  [ "$got_compact" = "$got_pretty_compact" ]
}

@test "multiple unexpected args cause error" {
  run r2j "{:a=>1}" "extra"
  assert_failure
  assert_line --partial "Unexpected argument"
}
