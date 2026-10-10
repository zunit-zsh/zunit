# A fixture with known line numbers. Do not reformat it without
# updating the line numbers asserted in tests/coverage/collector.zunit
covered_top_level='yes'

function coverage_fixture_covered() {
  local a=$1
  local b=$2
  echo $(( a + b ))
}

function coverage_fixture_never_called() {
  echo 'this line never runs'
}
