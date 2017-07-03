#!/usr/bin/env zunit

@test 'substring match' {
  run assert 'lo wo' is_substring_of 'hello world'

  assert "$output" is_empty
  assert $state equals 0
}

@test 'substring suffix match' {
  run assert 'world' is_substring_of 'hello world'

  assert "$output" is_empty
  assert $state equals 0
}

@test 'substring prefix match' {
  run assert 'hello' is_substring_of 'hello world'

  assert "$output" is_empty
  assert $state equals 0
}

@test 'whole word matches' {
  run assert 'red blue green' is_substring_of 'red blue green'

  assert "$output" is_empty
  assert $state equals 0
}

@test 'substring match failure' {
  run assert 'foo' is_substring_of 'elephants'

  assert "$output" same_as "'foo' is not a substring of 'elephants'"
  assert $state equals 1
}
