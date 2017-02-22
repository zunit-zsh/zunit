##########################################
# Functions for handling internal events #
##########################################

###
# Shutdown testing early
# Usually called if --fail-fast is specified
###
function _zunit_fail_shutdown() {
  # Kill the revolver process
  [[ -z $tap ]] && revolver stop

  echo $(color red bold 'Execution halted after failure')
  end_time=$((EPOCHREALTIME*1000))

  [[ -z $tap ]] && _zunit_output_results

  # Print end of HTML report
  if [[ -n $output_html ]]; then
    name='Execution halted after failure'
    _zunit_html_error >> $logfile_html
    _zunit_html_footer >> $logfile_html
  fi

  exit 1
}

###
# Output a success message
###
function _zunit_success() {
  [[ -n $output_text ]] && _zunit_tap_success "$@" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_success "$@" >> $logfile_html

  passed=$(( passed + 1 ))

  if [[ -n $tap ]]; then
    _zunit_tap_success "$@"
    return
  fi

  echo "$(color green '✔') ${name}"
}

###
# Output a failure message
###
function _zunit_failure() {
  local message="$1" output="${(@)@:2}"

  failed=$(( failed + 1 ))

  [[ -n $output_text ]] && _zunit_tap_failure "$@" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_failure "$@" >> $logfile_html

  if [[ -n $tap ]]; then
    _zunit_tap_failure "$@"
  else
    echo "$(color red '✘' ${name})"
    echo "  $(color red underline ${message})"
    echo "  $(color red ${output})"
  fi

  [[ -n $fail_fast ]] && _zunit_fail_shutdown
}

###
# Output a error message
###
function _zunit_error() {
  local message="$1" output="${(@)@:2}"

  errors=$(( errors + 1 ))

  [[ -n $output_text ]] && _zunit_tap_error "$@" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_error "$@" >> $logfile_html

  if [[ -n $tap ]]; then
    _zunit_tap_error "$@"
  else
    echo "$(color red '‼' ${name})"
    echo "  $(color red underline ${message})"
    echo "  $(color red ${output})"
  fi

  [[ -n $fail_fast ]] && _zunit_fail_shutdown
}

###
# Output a warning message
###
function _zunit_warn() {
  local message="$@"

  warnings=$(( warnings + 1 ))

  [[ -n $output_text ]] && _zunit_tap_warn "$@" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_warn "$@" >> $logfile_html

  if [[ -n $tap ]]; then
    _zunit_tap_warn "$@"
    return
  fi

  echo "$(color yellow '‼') ${name}"
  echo "  $(color yellow underline ${message})"
}

###
# Output a skipped test message
###
function _zunit_skip() {
  local message="$@"

  skipped=$(( skipped + 1 ))

  [[ -n $output_text ]] && _zunit_tap_skip "$@" >> $logfile_text
  [[ -n $output_html ]] && _zunit_html_skip "$@" >> $logfile_html

  if [[ -n $tap ]]; then
    _zunit_tap_skip "$@"
    return
  fi

  echo "$(color magenta '•') Skipped: ${name}"
  echo "  # ${message}"
}
