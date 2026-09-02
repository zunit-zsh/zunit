#############################
# Code coverage collection  #
#############################

###
# The file descriptor which coverage records are written to, and the
# path of the datafile behind it. Both are exported so that child
# processes are able to find them.
###
typeset -g ZUNIT_COVERAGE_FD
typeset -g ZUNIT_COVERAGE_DATA

###
# Hit counts for each line which was executed, keyed 'filepath:line'
###
typeset -gA zunit_coverage_hits

###
# The paths which coverage is measured within, and those which are
# never measured. Both are populated from .zunit.yml
###
typeset -ga zunit_coverage_paths
typeset -ga zunit_coverage_exclude

###
# The body of the DEBUG trap, which records each line as it is executed
#
# The trap is evaluated in the context of the code which is about to
# run, so $funcsourcetrace reports the file and the line at which the
# enclosing function was defined, and $LINENO the offset within that
# function's body. Adding the two together gives the absolute line
# number. At the top level of a script $funcsourcetrace is empty, and
# $LINENO is already absolute.
#
# $PWD is recorded alongside them, so that a relative path can still be
# resolved later if the code being measured changes directory.
#
# Records go to a dedicated file descriptor, so that they can never
# contaminate the output of the code being tested, and errors are
# discarded, since a failure to record coverage must never affect the
# result of a test.
###
typeset -g _zunit_coverage_trap='print -u $ZUNIT_COVERAGE_FD -r -- "$PWD|${funcsourcetrace[1]:-${ZSH_SCRIPT}:0}|$LINENO" 2>/dev/null'

###
# Open the coverage datafile and prepare to collect records
###
function _zunit_coverage_init() {
  local datafile="$1"

  # $funcsourcetrace lives in the parameter module
  zmodload zsh/parameter

  # Start from a clean slate, since a datafile left behind by a
  # previous run would be counted as part of this one
  ZUNIT_COVERAGE_DATA="$datafile"
  : > "$ZUNIT_COVERAGE_DATA" 2>/dev/null

  if [[ ! -w "$ZUNIT_COVERAGE_DATA" ]]; then
    echo "Coverage datafile at $ZUNIT_COVERAGE_DATA is not writable" >&2
    return 1
  fi

  # Let the shell pick the descriptor, rather than assuming that a
  # given number is free. It must be unset first, or zsh will complain
  # that the descriptor it holds is already in use
  unset ZUNIT_COVERAGE_FD
  exec {ZUNIT_COVERAGE_FD}>>"$ZUNIT_COVERAGE_DATA"

  export ZUNIT_COVERAGE_FD ZUNIT_COVERAGE_DATA
  zunit_coverage_hits=()
}

###
# Start recording. Preserves the exit status of the previous command,
# since it is called from within the test runner
###
function _zunit_coverage_enable() {
  local state=$?

  [[ -n $ZUNIT_COVERAGE_FD ]] && trap "$_zunit_coverage_trap" DEBUG

  return $state
}

###
# Stop recording. Preserves the exit status of the previous command,
# since the runner checks it immediately after a test has been run
###
function _zunit_coverage_disable() {
  local state=$?

  [[ -n $ZUNIT_COVERAGE_FD ]] && trap - DEBUG

  return $state
}

###
# Close the coverage datafile
###
function _zunit_coverage_finish() {
  [[ -n $ZUNIT_COVERAGE_FD ]] || return 0

  exec {ZUNIT_COVERAGE_FD}>&-
  unset ZUNIT_COVERAGE_FD
}

###
# Check whether coverage should be measured for a file
###
function _zunit_coverage_includes() {
  setopt localoptions extended_glob

  local file="$1" path

  # With no paths configured there is nothing to measure
  (( ${#zunit_coverage_paths} )) || return 1

  # Exclusions win over inclusions, so that a directory can be measured
  # with a subdirectory of it left out
  for path in $zunit_coverage_exclude; do
    [[ "$file" = "${path:a}"(|/*) ]] && return 1
  done

  for path in $zunit_coverage_paths; do
    [[ "$file" = "${path:a}"(|/*) ]] && return 0
  done

  return 1
}

###
# Read a datafile of coverage records into $zunit_coverage_hits
###
function _zunit_coverage_parse() {
  setopt localoptions extended_glob

  local datafile="${1:-$ZUNIT_COVERAGE_DATA}"
  local record entry count cwd location file defline lineno
  local -a bits

  [[ -n $datafile && -f $datafile ]] || return 0

  # A single test run produces a record for every command it executes,
  # the vast majority of them duplicates. Collapsing them before doing
  # any work in the shell turns thousands of iterations into dozens
  for record in ${(f)"$(sort "$datafile" | uniq -c)"}; do
    # Split the count `uniq -c` prepended from the record itself
    entry="${record##[[:space:]]#}"
    count="${entry%%[[:space:]]*}"
    entry="${entry#*[[:space:]]}"

    # A path may legitimately contain the separator, so the record is
    # read from the right, where the fields are known
    bits=("${(@s:|:)entry}")
    (( ${#bits} >= 3 )) || continue

    lineno="${bits[-1]}"
    location="${bits[-2]}"
    cwd="${(j:|:)bits[1,-3]}"

    file="${location%:*}"
    defline="${location##*:}"

    # Anything which isn't a pair of numbers pointing at a real file is
    # not code we can attribute. Test bodies are the common case, since
    # they are eval'd, and report against the test file
    [[ -n $file && $defline = <-> && $lineno = <-> ]] || continue
    [[ "${file[1]}" = '/' ]] || file="${cwd}/${file}"
    file="${file:a}"
    [[ -f "$file" ]] || continue
    _zunit_coverage_includes "$file" || continue

    lineno=$(( defline + lineno ))
    zunit_coverage_hits[${file}:${lineno}]=$(( ${zunit_coverage_hits[${file}:${lineno}]:-0} + count ))
  done
}

# vim:ft=zsh:et:sts=2:sw=2
