# ZUnit

[![Build Status](https://travis-ci.org/molovo/zunit.svg?branch=master)](https://travis-ci.org/molovo/zunit) [![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/molovo/zunit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

ZUnit is a powerful unit testing framework for ZSH

## Installation

> **WARNING**: Although the majority of ZUnit's functionality works as expected, it is in the early stages of development, and as such bugs are likely to be present. Please continue with caution, and [report any issues](https://github.com/molovo/zunit/issues/new) you may have.

### [Zulu](https://github.com/zulu-zsh/zulu)

```sh
zulu install zunit
```

### zplug

```sh
zplug "molovo/zunit", \
  as:command, \
  use:zunit
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

#### is_key_in

Asserts that a value is a key in a hash.

```sh
typeset -A hash; hash=(
  'a' 1
  'b' 2
  'c' 3
)
assert 'a' is_key_in ${(@kv)hash}
```

#### is_not_key_in

Asserts that a value is not a key in a hash.

```sh
typeset -A hash; hash=(
  'a' 1
  'b' 2
  'c' 3
)
assert 'x' is_not_key_in ${(@kv)hash}
```

#### is_value_in

Asserts that a value is a value in a hash.

```sh
typeset -A hash; hash=(
  'a' 1
  'b' 2
  'c' 3
)
assert 1 is_value_in ${(@kv)hash}
```

#### is_not_value_in

Asserts that a value is not a value in a hash.

```sh
typeset -A hash; hash=(
  'a' 1
  'b' 2
  'c' 3
)
assert 4 is_not_value_in ${(@kv)hash}
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

Asserts that the given path exists and is readable

```sh
assert /path/to/file is_readable
```

#### is_writable

Asserts that the given path exists and is writable

```sh
assert /path/to/file is_writable
```

#### is_executable

Asserts that the given path exists and is executable

```sh
assert /path/to/file is_executable
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

## Configuration

ZUnit is configured using a `.zunit.yml` file in the base of your project. The default configuration is as follows:

```yaml
tap: false
directories:
  tests: tests
  output: tests/_output
  support: tests/_support
```

### Bootstrap script

ZUnit will look in the support directory (`tests/_support` by default) for a file named `bootstrap`. If found, this is sourced prior to any tests being run. This bootstrap script can be used to install software, set environment variables and source programs required for your tests to run.

### Test time limits

ZUnit can enforce a time limit for tests, and will terminate them with an error if they run for longer than this. Just add the `time_limit` key to your `.zunit.yml`.

```yaml
time_limit: 5 # Will terminate tests after they have run for 5 seconds
```

> **NOTE:** Due to the way child processes are handled in earlier versions of ZSH, the `time_limit` setting is **ignored** for ZSH versions below **5.1.0**. This is necessary because in versions below 5.1.0, the exit state is never returned from the asynchronous process, which would cause tests to hang indefinitely.

### Setting up a new project

To set up ZUnit for a new project, just run `zunit init` in the project's root directory. This will create the `.zunit.yml` config file and relevant directories, including a bootstrap script and example test.

### [Travis CI](https://travis-ci.org) config

ZUnit can generate a `.travis.yml` file for you, which contains the build steps needed to install ZUnit's dependencies and then run tests. Just run `zunit init --travis` when initialising your project.

An example `.travis.yml` is below:

```yaml
addons:
  apt:
    packages:
      zsh
before_script:
- mkdir .bin
- curl -L https://raw.githubusercontent.com/molovo/revolver/master/revolver > .bin/revolver
- curl -L https://raw.githubusercontent.com/molovo/color/master/color.zsh > .bin/color
- curl -L https://raw.githubusercontent.com/molovo/zunit/master/zunit > .bin/zunit
- chmod u+x .bin/{color,revolver,zunit}
- export PATH="$PWD/.bin:$PATH"
script: zunit
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

### TAP Compatibility

ZUnit is capable of producing [TAP](http://testanything.org) compatible output, either printed to the screen or to an output log, based on options provided.

```sh
# Prints TAP compatible output to the screen
zunit --tap

# Prints TAP compatible output to the _output directory
zunit --output-text
```

### HTML Reports

ZUnit is capable of producing a detail HTML report, which you can view in your browser.

```sh
# Prints HTML report to the _output directory
zunit --output-html
```

### Risky Tests

By default, risky tests (those that make no assertions) raise a warning in the test output. To supress this behaviour, and allow risky tests to pass without warning, use the `--allow-risky` option.

```sh
zunit --allow-risky
```

## Contributing

All contributions are welcome, and encouraged. Please read our [contribution guidelines](contributing.md) and [code of conduct](code-of-conduct.md) for more information.

## License

Copyright (c) 2016 James Dinsdale <hi@molovo.co> (molovo.co)

ZUnit is licensed under The MIT License (MIT)

## Team

* [James Dinsdale](http://molovo.co)
