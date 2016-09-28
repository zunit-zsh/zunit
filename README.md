# ZUnit

ZUnit is a powerful unit testing framework for ZSH

## Installation

> **WARNING**: Although the majority of ZUnit's functionality works as expected, it is in the early stages of development, and as such bugs are likely to be present. Please continue with caution, and [report any issues](https://github.com/molovo/zunit/issues/new) you may have.

### [Zulu](https://github.com/zulu-zsh/zulu)

```sh
zulu install zunit
```

### Manual

```sh
git clone https://github.com/molovo/zunit
cd ./zunit
chmod u+x ./zunit
cp ./zunit /usr/local/bin
```

> For best results, the utilities [Color](https://github.com/molovo/color) and [Revolver](https://github.com/molovo/revolver) should be installed, and in your `$PATH`. The zulu installation method will install these dependencies for you.

## Writing Tests

### Test syntax

Tests in ZUnit have a simple syntax, which is inspired by the [BATS](https://github.com/sstephenson/bats) framework.

```sh
#!/usr/bin/env zunit

@test 'My first test' {
	# Test contents here
}
```

The body of each test can contain any valid ZSH code. The zunit shebang `#!/usr/bin/env zunit` **MUST** appear at the top of each test file, or ZUnit will not run it.

### Assertions

ZUnit comes with a powerful assertion library to aid you in writing tests. The `assert` helper function allows you to access each of the available assertions with a readable syntax.

The following assertions are available:

#### equals

Asserts that two integers are equal to each other.

```sh
assert 1 equals 1
```

#### not_equal_to

Asserts that two integers are not equal to each other.

```sh
assert 1 not_equal_to 0
```

#### same_as

Asserts that two strings are equal to each other.

```sh
assert 'test' same_as 'test'
```

#### different_to

Asserts that two strings are not equal to each other.

```sh
assert 'rainbows' different_to 'unicorns'
```

#### is_empty

Asserts that a string has a length of zero.

```sh
value=''
assert "$value" is_empty
```

#### is_not_empty

Asserts that a string has a length of greater than zero.

```sh
value='rainbows'
assert $value is_not_empty
```

#### matches

Asserts that a string matches a regular expression.

```sh
assert 'unicorns' matches '[a-z]{8}'
```

#### does_not_match

Asserts that a string does not match a regular expression.

```sh
assert 'rainbows' does_not_match '[0-9]+'
```

#### in

Asserts that a value is included in the comparison array.

```sh
assert 'a' in 'a' 'b' 'c'
```

#### not_in

Asserts that a value is not included in the comparison array.

```sh
assert 'a' not_in 'x' 'y' 'z'
```

#### exists

Asserts that the given path exists

```sh
assert /path/to/file exists
```

#### is_file

Asserts that the given path exists and is a file

```sh
assert /path/to/file is_file
```

#### is_dir

Asserts that the given path exists and is a directory

```sh
assert /path/to/dir is_dir
```

#### is_link

Asserts that the given path exists and is a symbolic link

```sh
assert /path/to/link is_link
```

#### is_readable

Asserts that the given path exists and is a symbolic readable

```sh
assert /path/to/file is_readable
```

### Loading scripts

Each of your tests is run in isolation, meaning that there is no variable or function leakage between tests. The `load` helper function will source a script into the test environment for you, allowing you to set up variables and functions etc.

You can load any absolute or relative file path, and for files ending in `.zsh` including the extension is optional.

```sh
# In /mypet.zsh
testing='Tada!'

# In /tests/myscript.zunit
@test 'Test loading scripts' {
	testing=''

	load ../myscript

	assert $testing is_not_empty
	assert $testing same_as 'Tada!'
}
```

### Running commands

You can run commands within your tests using the `run` helper, allowing you to make assertions on their exit status and output.

```sh
@test 'Test command output' {
	# Run the command, including arguments
	run ls ~/my-dir

	# $state contains the exit status
	assert $state equals 0

	# The command's output is stored in $output
	assert $output is_not_empty

	# Each line of the output is also stored in
	# the $lines array, allowing you to run assertions
	# against individual lines of the output
	assert "$lines[3]" equals 'my-third-file'
}
```

### Setup and Teardown

ZUnit provides `@setup` and `@teardown` methods, which will be run before and after each test in the file.

```sh
@setup {
	SOME_VAR='rainbows'
}

@teardown {
	unset SOME_VAR
}

@test 'Check value of SOME_VAR' {
	assert $SOME_VAR same_as 'rainbows'
}

@test 'Change value of SOME_VAR' {
	SOME_VAR='unicorns'
	assert $SOME_VAR same_as 'unicorns'
}

@test 'Check value of SOME_VAR again' {
	# Check will fail, because the variable was unset in
	# the @teardown method, and then reset to 'rainbows'
	# when @setup was run again.
	assert $SOME_VAR same_as 'unicorns'
}
```

## Running Tests

The CLI program `zunit` is used to run tests.

```sh
# Runs all test files in ./tests
zunit

# Runs all test files in ./other_tests
zunit other_tests

# Runs all tests in the file ./tests/a-test-file
zunit tests/a-test-file

# Runs all tests, and exists immediately after the first failure
zunit --fail-fast
```
