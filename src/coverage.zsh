###############################
# Functions for code coverage #
###############################

function _zunit_coverage_start() {
  trap '_zunit_mark_covered $testfile $LINENO' DEBUG
}

function _zunit_coverage_end() {
  trap '' DEBUG
  echo ${_zunit_coverage_data_${testfile}}
}

function _zunit_coverage_calculate() {

}

function _zunit_coverage_output() {

}

function _zunit_coverage_mark() {
  local file="$1" line="$2"

  safe_name=$(_zunit_encode_test_name $file)

  _zunit_coverage_data_${safe_name}[$line]=1
}

function _zunit_coverage_build_file_list() {
  setopt EXTENDED_GLOB
  if [[ -n $zunit_config_coverage_include ]]; then
    for glob in $zunit_config_coverage_include; do
      for file in ${~glob}; do
        safe_name=$(_zunit_encode_test_name $file)
        typeset -gA _zunit_coverage_data_${safe_name}
        _zunit_coverage_data_${safe_name}=()

        lines=($(cat $file))

        i=1
        for line in $lines; do
          if [[ $line =~ '(\s+)?#.*' || $line = $'\n' ]]; then
            _zunit_coverage_data_${safe_name}[$i]=2
            continue
          fi

          _zunit_coverage_data_${safe_name}[$i]=0

          i=$(( i + 1 ))
        done
      done
    done
  fi
}
