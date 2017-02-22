################################
# Helpers for use within tests #
################################

###
# Find a file, and load it into the environment
###
function load() {
  local name="$1"
  local filename

  # If filepath is absolute, then use it as is
  if [[ "${name:0:1}" = "/" ]]; then
    filename="${name}"
  # If it's relative, prepend the test directory
  else
    filename="$testdir/${name}"
  fi

  # Check if the file exists
  if [[ -f "$filename" ]]; then
    # Source the file and exit if it's found
    source "$filename"
    return 0
  fi

  # Perform the check again, adding the .zsh extension
  if [[ -f "$filename.zsh" ]]; then
    # Source the file and exit if it's found
    source "$filename.zsh"
    return 0
  fi

  # Output an error message to the user
  echo "File $filename does not exist" >&2
  exit 1
}

###
# Run an external command and capture its output and exit status
###
function run() {
  # Stop the shell from exiting on error temporarily
  unsetopt ERR_EXIT

  # Preserve current $IFS
  local oldIFS=$IFS name
  local -a cmd lines

  # Grab the first argument
  cmd=(${@[@]})
  name="${cmd[1]}"

  # If the command is not an existing command or file,
  # then prepend the test directory to the path
  type $name > /dev/null
  if [[ $? -ne 0 && ! -f $name && -f "$testdir/${name}" ]]; then
    cmd[1]="$testdir/${name}"
  fi

  # Store full output in a variable
  output=$("${cmd[@]}" 2>&1)

  # Get the process exit state
  state="$?"

  # Store individual lines of output in an array
  IFS=$'\n'
  lines=($output)

  # Restore $IFS
  IFS=$oldIFS

  # Restore the exit on error state
  setopt ERR_EXIT
}

###
# Redirect the assertion shorthand to the correct function
###
function assert() {
  local value=$1 assertion=$2
  local -a comparisons

  IFS=$'\n'

  comparisons=(${(@)@:3})

  if [[ -z $assertion ]]; then
    assertion=$value
    value=""
  fi

  if (( ! $+functions[_zunit_assert_${assertion}] )); then
    echo "$(color red "Assertion $assertion does not exist")"
    exit 127
  fi

  _zunit_assertion_count=$(( _zunit_assertion_count + 1 ))

  "_zunit_assert_${assertion}" $value ${(@f)comparisons[@]}

  local state=$?

  if [[ $state -ne 0 ]]; then
    exit $state
  fi

  IFS=$oldIFS
}

###
# Mark the current test as skipped
###
function skip() {
  # Exit code 48 will skip the test, so all we have to do
  # to mark the test as skipped is exit.
  # The reason for skipping is echoed to stdout first, so that
  # it can be picked up by the error handler
  echo "$@"
  exit 48
}
