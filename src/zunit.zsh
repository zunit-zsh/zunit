#!/usr/bin/env zsh

######################
# Main zunit process #
######################

###
# Output usage information and exit
###
function _zunit_usage() {
  echo "$(color yellow 'Usage:')"
  echo "  zunit [options] [command] [tests...]"
  echo
  echo "$(color yellow 'Commands:')"
  echo "  init               Bootstrap zunit in a new project"
  echo "  run [tests...]     Run tests"
  echo
  echo "$(color yellow 'Options:')"
  echo "  -h, --help         Output help text and exit"
  echo "  -v, --version      Output version information and exit"
  echo "  -f, --fail-fast    Stop the test runner immediately after the first failure"
  echo "  -t, --tap          Output results in a TAP compatible format"
  echo "      --output-text  Print results to a text log, in TAP compatible format"
  echo "      --output-html  Print results to a HTML page"
  echo "      --allow-risky  Supress warnings generated for risky tests"
}

###
# Output the version number
###
function _zunit_version() {
  echo '0.6.0'
}

###
# The main zunit process
###
function _zunit() {
  local help version ctx="$1" missing_dependencies=0 missing_config=1

  if [[ -f .zunit.yml ]]; then
    # Try and parse the config file within a subprocess,
    # to avoid killing the main thread
    $(eval $(_zunit_parse_yaml .zunit.yml 'zunit_config_') >/dev/null 2>&1)
    if [[ $? -eq 0 ]]; then
      # The config file was parsed successfully, so we Perform the parse
      # again, but this time on the main thread so that the config vars are
      # loaded into the enviroment
      eval $(_zunit_parse_yaml .zunit.yml 'zunit_config_') >/dev/null 2>&1
      missing_config=0
    else
      # The config file failed to parse, so we report this to the user and exit
      echo "\033[0;31mFailed to parse config file\033[0;m" >&2
      exit 1
    fi
  fi

  # Check for the 'color' dependency
  $(type color >/dev/null 2>&1)
  if [[ $? -ne 0 ]]; then
    # 'color' could not be found, so print an error message
    missing_dependencies=$(( missing_dependencies + 1 ))
    echo "\033[0;31mMissing required dependency: Color - https://github.com/molovo/color\033[0;m" >&2
  fi

  # Check for the 'revolver' dependency
  $(type revolver >/dev/null 2>&1)
  if [[ $? -ne 0 ]]; then
    # 'revolver' could not be found, so print an error message
    missing_dependencies=$(( missing_dependencies + 1 ))
    echo "\033[0;31mMissing required dependency: Revolver - https://github.com/molovo/revolver\033[0;m" >&2
  fi

  # If any missing dependencies have been found, we can't run tests, so we exit
  [[ $missing_dependencies -gt 0 ]] && exit 1

  zparseopts -D -E \
    h=help -help=help \
    v=version -version=version

  # If the version option is passed,
  # output version information and exit
  if [[ -n $version ]]; then
    _zunit_version
    exit 0
  fi

  # Check which command has been passed, and run it. If the command
  # is not recognised, then we'll assume it's a test file and pass
  # it to `zunit run`, since that will catch it if it's not a valid file
  case "$ctx" in
    init )
      # If the help option is passed,
      # output usage information and exit
      if [[ -n $help ]]; then
        _zunit_init_usage
        exit 0
      fi

      _zunit_init "${(@)@:2}"
      ;;
    run )
      # If the help option is passed,
      # output usage information and exit
      if [[ -n $help ]]; then
        _zunit_run_usage
        exit 0
      fi

      _zunit_run "${(@)@:2}"
      ;;
    * )
      # If the help option is passed,
      # output usage information and exit
      if [[ -n $help ]]; then
        _zunit_usage
        exit 0
      fi

      _zunit_run "$@"
      ;;
  esac
}

_zunit "$@"