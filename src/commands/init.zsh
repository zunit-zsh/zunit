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

  local yaml="tap: false
directories:
  tests: tests
  output: tests/_output
  support: tests/_support"

  local example="#!/usr/bin/env zunit

@test 'Example' {
  assert "'"true"'" same_as "'"false"'"
}"

  local bootstrap="#!/usr/bin/env zsh

# Write your bootstrap code here"

  local travis_yml='addons:
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
  script: zunit'

  if [[ -f "$PWD/.zunit.yml" ]]; then
    echo $(color red "Zunit config file already exists at $PWD/.zunit.yml") >&2
    exit 1
  else
    echo "$yaml" > "$PWD/.zunit.yml"
  fi

  if [[ -d "$PWD/tests" ]]; then
    echo $(color red "Directory already exists at $PWD/tests") >&2
    exit 1
  else
    mkdir -p tests/_{output,support}
    touch tests/_{output,support}/.gitkeep

    echo "$bootstrap" > "$PWD/tests/_support/bootstrap"
    echo "$example" > "$PWD/tests/example.zunit"
  fi

    #statements
  if [[ -n $with_travis ]]; then
    if [[ -f "$PWD/.travis.yml" ]]; then
      echo $(color red "Travis config already exists at $PWD/.travis.yml") >&2
      exit 1
    else
      echo "$travis_yml" > "$PWD/.travis.yml"
    fi
  fi
}
