#!/usr/bin/env zunit

@test 'not a substring of succes' {
    run assert 'foo' is_not_substring_of 'yellow'

    assert "$output" is_empty
    assert $state equals 0
}

@test 'not a substring of failure' {
    run assert 'foo' is_not_substring_of 'foobar'
    
    assert "$output" same_as "'foo' is a substring of 'foobar'"
    assert $state equals 1
}
