###########################
# The 'zunit run' command #
###########################

###
# Output usage information and exit
###
function _zunit_run_usage() {
  echo "$(color yellow 'Usage:')"
  echo "  zunit run [options] [tests...]"
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
# Format a ms timestamp in a human-readable format
###
function _zunit_human_time() {
  local ms=$1
  local tmp=$(( $1 / 1000 ))
  local days=$(( tmp / 60 / 60 / 24 ))
  local hours=$(( tmp / 60 / 60 % 24 ))
  local minutes=$(( tmp / 60 % 60 ))
  local seconds=$(( tmp % 60 ))
  (( $days > 0 )) && print -n "${days}d "
  (( $hours > 0 )) && print -n "${hours}h "
  (( $minutes > 0 )) && print -n "${minutes}m "
  (( $seconds > 5 )) && print -n "${seconds}s "
  (( $seconds < 30 )) && (( $seconds > 5 )) && print -n "$(( ms - $((seconds*1000)) ))ms"
  (( $tmp <= 5 )) && print -n "${1}ms"
}

###
# Output test results
###
function _zunit_output_results() {
  integer elapsed=$(( end_time - start_time ))
  echo
  echo "$total tests run in $(_zunit_human_time $elapsed)"
  echo
  echo "$(color yellow underline 'Results')                        "
  echo "$(color green '✔') Passed      $passed                    "
  echo "$(color red '✘') Failed      $failed                      "
  echo "$(color red '‼') Errors      $errors                      "
  echo "$(color magenta '•') Skipped     $skipped                 "
  echo "$(color yellow '‼') Warnings    $warnings                 "
  echo

  [[ -n $output_text ]] && echo "TAP report written at $PWD/$logfile_text"
  [[ -n $output_html ]] && echo "HTML report written at $PWD/$logfile_html"
}

###
# Execute a test and store the result
###
function _zunit_execute_test() {
  local name="$1" body="$2"

  if [[ -n $body ]] && [[ -n $name ]]; then
    # Update the progress indicator
    [[ -z $tap ]] && revolver update "${name}"

    # Make sure we don't already have a function defined
    (( $+functions[__zunit_tmp_test_function] )) && \
      unfunction __zunit_tmp_test_function

    func="function __zunit_tmp_test_function() {
      setopt ERR_EXIT
      integer state
      integer _zunit_assertion_count=0
      local output
      typeset -a lines

      if (( $+functions[__zunit_test_setup] )); then
        __zunit_test_setup >/dev/null 2>&1
      fi

      ${body}

      if (( $+functions[__zunit_test_teardown] )); then
        __zunit_test_teardown >/dev/null 2>&1
      fi

      [[ \$_zunit_assertion_count -gt 0 ]] || return 248
    }"

    # Quietly eval the body into a variable as a first test
    output=$(eval "$(echo "$func")" 2>&1)

    total=$(( total + 1 ))

    # Check the status of the eval, and output any errors
    if [[ $? -ne 0 ]]; then
      _zunit_error 'Failed to parse test body' $output

      return 126
    fi

    # Run the eval again, this time within the current context so that
    # the function is registered in the current scope
    eval "$(echo "$func")" 2>/dev/null

    # Any errors should have been caught above, but if the function
    # does not exist, we can't go any further
    if (( ! $+functions[__zunit_tmp_test_function] )); then
      _zunit_error 'Failed to parse test body'

      return 126
    fi

    autoload is-at-least

    # Check if a time limit has been specified
    if is-at-least 5.1.0 && [[ -n $zunit_config_time_limit ]]; then
      # Create a wrapper function around the test
      __zunit_async_test_wrapper() {
        local pid

        # Get the current timestamp, and the time limit, and use those to
        # work out the kill time for the sub process
        integer time_limit=$(( ${zunit_config_time_limit:-30} * 1000 ))
        integer time=$(( EPOCHREALTIME * 1000 ))
        integer kill_time=$(( $time + $time_limit ))

        # Launch the test function asynchronously and store its PID
        __zunit_tmp_test_function &
        pid=$!

        # While the child process is still running
        while kill -0 $pid >/dev/null 2>&1; do
          # Check that the kill time has not yet been reached
          time=$(( EPOCHREALTIME * 1000 ))
          if [[ $time -gt $kill_time ]]; then
            # The kill time has been reached, kill the child process,
            # and exit the wrapper function
            kill -9 $pid >/dev/null 2>&1
            exit 78
          fi
        done

        # Use wait to get the exit code from the background process,
        # and return that so that the test result can be deduced
        wait $pid
        return $?
      }

      # Launch the async wrapper, and capture the output in a variable
      output="$(__zunit_async_test_wrapper 2>&1)"
    else
      # Launch the test, and capture the output in a variable
      output="$(__zunit_tmp_test_function 2>&1)"
    fi

    # Output the result to the user
    state=$?
    if [[ $state -eq 48 ]]; then
      _zunit_skip $output

      return
    elif [[ $state -eq 78 ]]; then
      _zunit_error "Test took too long to run. Terminated after ${zunit_config_time_limit:-30} seconds" $output

      return
    elif [[ -z $allow_risky && $state -eq 248 ]]; then
      _zunit_warn 'No assertions were run, test is risky'

      return
    elif [[ -n $allow_risky && $state -eq 248 ]] || [[ $state -eq 0 ]]; then
      _zunit_success

      return
    else
      _zunit_failure $output

      return 1
    fi
  fi
}

###
# Encode test name into a value which can be used as a hash key
###
function _zunit_encode_test_name() {
  echo "$1" | tr A-Z a-z \
            | tr _ ' ' \
            | tr - ' ' \
            | tr -s ' ' \
            | sed 's/\- /-/' \
            | sed 's/ \-/-/' \
            | tr ' ' "-"
}

###
# Run all tests within a file
###
function _zunit_run_testfile() {
  local testbody testname pattern \
        setup teardown \
        testfile="$1" testdir="$(dirname "$testfile")"
  local -a lines tests test_names
  tests=()
  test_names=()

  # Update status message
  [[ -z $tap ]] && revolver update "Loading tests from $testfile"

  # A regex pattern to match test declarations
  pattern='^ *@test  *([^ ].*)  *\{ *(.*)$'

  # Loop through each of the lines in the file
  local oldIFS=$IFS
  IFS=$'\n' lines=($(cat $testfile))
  IFS=$oldIFS
  for line in $lines[@]; do
    # Match current line against pattern
    if [[ "$line" =~ $pattern ]]; then
      # Get test name from matches
      testname="${line[(( ${line[(i)[\']]}+1 )),(( ${line[(I)[\']]}-1 ))]}"
      test_names=($test_names $testname)
      tests[${#test_names}]=''
    elif [[ "$line" =~ '^@setup([ ])?\{$' ]]; then
      setup=''
      parsing_setup=true
    elif [[ "$line" =~ '^@teardown([ ])?\{$' ]]; then
      teardown=''
      parsing_teardown=true
    elif [[ "$line" = '}' ]]; then
      testname=''
      parsing_setup=''
      parsing_teardown=''
    else
      if [[ -n $testname ]]; then
        tests[${#test_names}]+="$line"$'\n'
        continue
      fi

      if [[ -n $parsing_setup ]]; then
        setup+="$line"$'\n'
        continue
      fi

      if [[ -n $parsing_teardown ]]; then
        teardown+="$line"$'\n'
        continue
      fi
    fi
  done

  if [[ -n $setup ]]; then
    setupfunc="function __zunit_test_setup() {
      ${setup}
    }"

    # Quietly eval the body into a variable as a first test
    output=$(eval "$(echo "$setupfunc")" 2>&1)

    # Check the status of the eval, and output any errors
    if [[ $? -ne 0 ]]; then
      _zunit_error "Failed to parse setup method" $output

      return 126
    fi

    # Run the eval again, this time within the current context so that
    # the function is registered in the current scope
    eval "$(echo "$setupfunc")" 2>/dev/null

    # Any errors should have been caught above, but if the function
    # does not exist, we can't go any further
    if (( ! $+functions[__zunit_test_setup] )); then
      _zunit_error "Failed to parse setup method"

      return 126
    fi
  fi

  if [[ -n $teardown ]]; then
    teardownfunc="function __zunit_test_teardown() {
      ${teardown}
    }"

    # Quietly eval the body into a variable as a first test
    output=$(eval "$(echo "$teardownfunc")" 2>&1)

    # Check the status of the eval, and output any errors
    if [[ $? -ne 0 ]]; then
      _zunit_error "Failed to parse teardown method" $output

      return 126
    fi

    # Run the eval again, this time within the current context so that
    # the function is registered in the current scope
    eval "$(echo "$teardownfunc")" 2>/dev/null

    # Any errors should have been caught above, but if the function
    # does not exist, we can't go any further
    if (( ! $+functions[__zunit_test_teardown] )); then
      _zunit_error "Failed to parse teardown method"

      return 126
    fi
  fi

  # Loop through each of the tests and execute it
  integer i=1
  local name body
  for name in "${test_names[@]}"; do
    body="${tests[$i]}"
    _zunit_execute_test "$name" "$body"
    i=$(( i + 1 ))
  done

  (( $+functions[__zunit_test_setup] )) && unfunction __zunit_test_setup
  (( $+functions[__zunit_test_teardown] )) && unfunction __zunit_test_teardown
  (( $+functions[__zunit_tmp_test_function] )) && unfunction __zunit_tmp_test_function
}

###
# Parse a list of arguments
###
function _zunit_parse_argument() {
  local argument="$1"

  # If the argument begins with an underscore, then it
  # should not be run, so we skip it
  if [[ "${argument:0:1}" = "_" || "$(basename $argument | cut -c 1)" = "_" ]]; then
    return
  fi

  # If the argument is a directory
  if [[ -d $argument ]]; then
    # Loop through each of the files in the directory
    for file in $(find $argument -mindepth 1 -maxdepth 1); do
      # Run it through the parser again
      _zunit_parse_argument $file
    done

    return
  fi

  # If it is a valid file
  if [[ -f $argument ]]; then
    # Grab the first line of the file
    line=$(cat $argument | head -n 1)

    # Check for the zunit shebang
    if [[ $line = "#!/usr/bin/env zunit" ]]; then
      # Add it to the array
      testfiles[(( ${#testfiles} + 1 ))]=($argument)
      return
    fi

    # The test file does not contain the zunit shebang, therefore
    # we can't trust that running it will not be harmful, and throw
    # a fatal error
    echo $(color red "File '$argument' is not a valid zunit test file") >&2
    echo "Test files must contain the following shebang on the first line" >&2
    echo "  #!/usr/bin/env zunit" >&2
    exit 126
  fi

  # The file could not be found, so we throw a fatal error
  echo $(color red "Test file or directory '$argument' could not be found") >&2
  exit 126
}

###
# Run tests
###
function _zunit_run() {
  local -a arguments testfiles
  local fail_fast tap allow_risky
  local output_text logfile_text output_html logfile_html

  zmodload zsh/datetime
  local start_time=$((EPOCHREALTIME*1000)) end_time

  zparseopts -D -E \
    h=help -help=help \
    v=version -version=version \
    f=fail_fast -fail-fast=fail_fast \
    t=tap -tap=tap \
    -output-text=output_text \
    -output-html=output_html \
    -allow-risky=allow_risky

  if [[ -n $tap ]] || [[ "$zunit_config_tap" = "true" ]]; then
    tap=1
    echo 'TAP version 13'
  fi

  if [[ -z $tap ]]; then
    # Print version information
    echo $(color yellow 'Launching ZUnit')
    echo "ZUnit: $(_zunit_version)"
    echo "ZSH:   $(zsh --version)"
    echo
  fi

  if [[ -n $output_text ]]; then
    if [[ $missing_config -eq 1 ]]; then
      echo $(color red '.zunit.yml could not be found. Run `zulu init`')
      exit 1
    fi

    if [[ -z $zunit_config_directories_output ]]; then
      echo $(color red 'Output directory must be specified in .zunit.yml')
      exit 1
    fi
  fi

  if [[ -n $output_text ]]; then
    logfile_text="$zunit_config_directories_output/output.txt"
    echo 'TAP version 13' > $logfile_text
  fi

  if [[ -n $output_html ]]; then
    logfile_html="$zunit_config_directories_output/output.html"
    _zunit_html_header > $logfile_html
  fi

  if [[ -n $zunit_config_directories_support ]]; then
    local support="$zunit_config_directories_support"
    if [[ ! -d $support ]]; then
      echo $(color red "Support directory at $support is missing")
      exit 1
    fi

    if [[ -f "$support/bootstrap" ]]; then
      source "$support/bootstrap"
      echo "$(color green '✔') Sourced bootstrap script $support/bootstrap"
    fi
  fi

  arguments=("$@")
  testfiles=()

  # Start the progress indicator
  [[ -z $tap ]] && revolver start 'Loading tests'

  # If no arguments are passed, use the current directory
  if [[ ${#arguments} -eq 0 ]]; then
    if [[ -n $zunit_config_directories_tests ]]; then
      arguments=("$zunit_config_directories_tests")
    else
      arguments=("tests")
    fi
  fi

  # Loop through each of the passed arguments
  local argument
  for argument in $arguments; do
    # Parse the argument, so that we end up with a list of valid files
    _zunit_parse_argument $argument
  done

  # Loop through each of the test files and run them
  local line
  local total=0 passed=0 failed=0 errors=0 warnings=0 skipped=0
  for testfile in $testfiles; do
    _zunit_run_testfile $testfile
  done

  end_time=$((EPOCHREALTIME*1000))

  [[ -n $tap ]] && echo "1..$total"
  [[ -n $output_text ]] && echo "1..$total" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_footer >> $logfile_html

  [[ -z $tap ]] && _zunit_output_results && revolver stop

  [[ $(( $passed + $skipped )) -eq $total ]]
}
