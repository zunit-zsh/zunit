############################
# The 'zunit init' command #
############################

###
# Output usage information and exit
###
function _zunit_init_usage() {
  echo "$(color yellow 'Usage:')"
  echo "  zunit init [options]"
  echo
  echo "$(color yellow 'Options:')"
  echo "  -h, --help         Output help text and exit"
  echo "  -v, --version      Output version information and exit"
  echo "  -t, --travis       Generate .travis.yml in project"
}

###
# Parse a YAML config file
# Based on https://gist.github.com/pkuczynski/8665367
###
function _zunit_parse_yaml() {
  local s w fs prefix=$2
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\(${s}\)\(${w}\)${s}:${s}\"\(.*\)\"${s}\$|\1${fs}\2${fs}\3|p" \
      -e "s|^\(${s}\)\(${w}\)${s}[:-]${s}\(.*\)${s}\$|\1${fs}\2${fs}\3|p" "$1" |
  awk -F"${fs}" '{
  indent = length($1)/2;
  vname[indent] = $2;
  for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
          vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
          printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
      }
  }' | sed 's/_=/+=/g'
}

function _zunit_init() {
  local with_travis

  zparseopts -D t=with_travis -travis=with_travis

  # The contents of .zunit.yml
  local yaml="tap: false
directories:
  tests: tests
  output: tests/_output
  support: tests/_support
time_limit: 0
fail_fast: false
allow_risky: false"

  # An example test file
  local example="#!/usr/bin/env zunit

@test 'Example' {
  assert "'"true"'" same_as "'"false"'"
}"

  # An empty bootstrap script
  local bootstrap="#!/usr/bin/env zsh

# Write your bootstrap code here"

  # An example .travis.yml config
  local travis_yml="addons:
  apt:
    packages:
      zsh
install:
  - mkdir .bin
  - curl -L https://github.com/zunit-zsh/zunit/releases/download/v$(_zunit_version)/zunit > .bin/zunit
  - curl -L https://raw.githubusercontent.com/molovo/revolver/master/revolver > .bin/revolver
  - curl -L https://raw.githubusercontent.com/molovo/color/master/color.zsh > .bin/color
before_script:
  - chmod u+x .bin/{color,revolver,zunit}
  - export PATH=\"\$PWD/.bin:\$PATH\"
script: zunit"

  # Check that a config file doesn't already exist so that
  # we don't overwrite it
  if [[ -f "$PWD/.zunit.yml" ]]; then
    echo $(color yellow "ZUnit config file already exists at $PWD/.zunit.yml. Skipping...")
  else
    # Write the contents to the config file
    echo "Writing ZUnit config file to $PWD/.zunit.yml"
    echo "$yaml" > "$PWD/.zunit.yml"
  fi

  # Check that the tests directory doesn't already exist so that
  # we don't overwrite it
  if [[ -d "$PWD/tests" ]]; then
    echo $(color yellow "Test directory already exists at $PWD/tests. Skipping...")
  else
    echo "Creating test directory at $PWD/tests"
    # Create the directory structure for tests
    mkdir -p tests/_{output,support}
    touch tests/_{output,support}/.gitkeep

    # Save the bootstrap script and example test
    echo "$bootstrap" > "$PWD/tests/_support/bootstrap"
    echo "$example" > "$PWD/tests/example.zunit"
  fi

  # If travis config has been requested
  if [[ -n $with_travis ]]; then
    # Check that a travis config doesn't already exist so that
    # we don't overwrite it
    if [[ -f "$PWD/.travis.yml" ]]; then
      echo $(color yellow "Travis config already exists at $PWD/.travis.yml. Skipping...")
    else
      echo "Writing Travis CI config to $PWD/.travis.yml"
      # Write the contents to the config file
      echo "$travis_yml" > "$PWD/.travis.yml"
    fi
  fi
}
