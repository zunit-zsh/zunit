#!/usr/bin/env zunit

@test 'substring matches' {
  assert 'world' is_substring_of 'hello world'
  assert 'hello' is_substring_of 'hello world'
  assert 'lo wo' is_substring_of 'hello world'
  assert '*' is_substring_of '-*-'
}

@test 'whole word matches' {
  assert 'red blue green' is_substring_of 'red blue green'
  assert '*---*' is_substring_of '*---*'
}
