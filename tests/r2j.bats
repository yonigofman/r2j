#!/usr/bin/env bats

# Path to the CLI under test
R2J="./bin/r2j"

setup() {
  chmod +x "$R2J"
}

@test "simple key/value conversion" {
  run $R2J "{:foo=>'bar'}"
  [ "$status" -eq 0 ]
  [ "$output" = '{"foo":"bar"}' ]
}

@test "integer value conversion" {
  run $R2J "{:num=>123}"
  [ "$status" -eq 0 ]
  [ "$output" = '{"num":123}' ]
}

@test "boolean and nil conversion" {
  run $R2J "{:a=>true, :b=>false, :c=>nil}"
  [ "$status" -eq 0 ]
  [ "$output" = '{"a":true,"b":false,"c":null}' ]
}

@test "symbol value conversion" {
  run $R2J "{:status=>:ok}"
  [ "$status" -eq 0 ]
  [ "$output" = '{"status":"ok"}' ]
}

@test "nested hash conversion" {
  run $R2J "{:outer=>{:inner=>42}}"
  [ "$status" -eq 0 ]
  [ "$output" = '{"outer":{"inner":42}}' ]
}

@test "stdin piping works" {
  run bash -c "echo '{:foo=>'bar'}' | $R2J"
  [ "$status" -eq 0 ]
  [ "$output" = '{"foo":"bar"}' ]
}

@test "--pretty flag works when jq is installed" {
  if command -v jq >/dev/null; then
    run $R2J --pretty "{:foo=>'bar'}"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"foo": "bar"'* ]]  # jq pretty-prints with indentation
  else
    skip "jq not installed"
  fi
}

@test "--help flag shows usage" {
  run $R2J --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE:"* ]]
}
