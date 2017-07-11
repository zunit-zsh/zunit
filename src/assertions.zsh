################################
# Internal assertion functions #
################################

###
# Assert one string is a substring of another
###
function _zunit_assert_is_substring_of() {
  local value=$1 comparison=$2

  [[ "$comparison" = *"$value"* ]] && return 0

  echo "'$value' is not a substring of '$comparison'"
  exit 1
}

###
# Assert one string is not a substring of another
###
function _zunit_assert_is_not_substring_of() {
  local value=$1 comparison=$2

  [[ "$comparison" != *"$value"* ]] && return 0

  echo "'$value' is a substring of '$comparison'"
  exit 1
}

###
# Assert one string contains another
###
function _zunit_assert_contains() {
  local value=$1 comparison=$2

  [[ "$value" = *"$comparison"* ]] && return 0

  echo "'$value' does not contain '$comparison'"
  exit 1
}

###
# Assert one string does not contain another
###
function _zunit_assert_does_not_contain() {
  local value=$1 comparison=$2

  [[ "$value" != *"$comparison"* ]] && return 0

  echo "'$value' contains '$comparison'"
  exit 1
}

###
# Assert that two integers are equal
###
function _zunit_assert_equals() {
  local value=$1 comparison=$2

  [[ $value -eq $comparison ]] && return 0

  echo "'$value' is not equal to '$comparison'"
  exit 1
}

###
# Assert that two integers are not equal
###
function _zunit_assert_not_equal_to() {
  local value=$1 comparison=$2

  [[ $value -ne $comparison ]] && return 0

  echo "'$value' is equal to '$comparison'"
  exit 1
}

###
# Assert that an integer is positive
###
function _zunit_assert_is_positive() {
  local value=$1 comparison=$2

  [[ $value -gt 0 ]] && return 0

  echo "'$value' is not positive"
  exit 1
}

###
# Assert that an integer is negative
###
function _zunit_assert_is_negative() {
  local value=$1 comparison=$2

  [[ $value -lt 0 ]] && return 0

  echo "'$value' is not negative"
  exit 1
}

###
# Assert that an integer is greater than the comparison
###
function _zunit_assert_is_greater_than() {
  local value=$1 comparison=$2

  [[ $value -gt $comparison ]] && return 0

  echo "'$value' is not greater than '$comparison'"
  exit 1
}

###
# Assert that an integer is less than the comparison
###
function _zunit_assert_is_less_than() {
  local value=$1 comparison=$2

  [[ $value -lt $comparison ]] && return 0

  echo "'$value' is not less than '$comparison'"
  exit 1
}

###
# Assert that two string are the same
###
function _zunit_assert_same_as() {
  local value=$1 comparison=$2

  [[ $value = $comparison ]] && return 0

  echo "'$value' is not the same as '$comparison'"
  exit 1
}

###
# Assert that two string are different
###
function _zunit_assert_different_to() {
  local value=$1 comparison=$2

  [[ $value != $comparison ]] && return 0

  echo "'$value' is the same as '$comparison'"
  exit 1
}

###
# Assert that a value is empty
###
function _zunit_assert_is_empty() {
  local value=$1

  [[ -z ${value[@]} ]] && return 0

  echo "'${value[@]}' is not empty"
  exit 1
}

###
# Assert that a value is not empty
###
function _zunit_assert_is_not_empty() {
  local value=$1

  [[ -n ${value[@]} ]] && return 0

  echo "value is empty"
  exit 1
}

###
# Assert that the value matches a regex pattern
###
function _zunit_assert_matches() {
  local value=$1 pattern=$2

  [[ $value =~ $pattern ]] && return 0

  echo "'$value' does not match /$pattern/"
  exit 1
}

###
# Assert that the value does not match a regex pattern
###
function _zunit_assert_does_not_match() {
  local value=$1 pattern=$2

  [[ ! $value =~ $pattern ]] && return 0

  echo "'$value' matches /$pattern/"
  exit 1
}

###
# Assert that a value is found in an array
###
function _zunit_assert_in() {
  local i found=0 value=$1
  local -a array
  array=(${(@)@:2})

  for i in ${(@f)array}; do
    [[ $i = $value ]] && found=1
  done


  [[ $found -eq 1 ]] && return 0

  echo "'$value' is not in (${(@f)array})"
  exit 1
}

###
# Assert that a value is not found in an array
###
function _zunit_assert_not_in() {
  local i found=0 value=$1
  local -a array
  array=(${(@)@:2})

  for i in ${(@f)array}; do
    [[ $i = $value ]] && found=1
  done

  [[ $found -eq 0 ]] && return 0

  echo "'$value' is in (${(@f)array})"
  exit 1
}

###
# Assert that a value is a key in a hash
###
function _zunit_assert_is_key_in() {
  local i found=0 value=$1
  local -A hash
  hash=(${(@)@:2})

  for k v in ${(@kv)hash}; do
    [[ $k = $value ]] && found=1
  done

  [[ $found -eq 1 ]] && return 0

  echo "'$value' is not a key in (${(@kv)hash})"
  exit 1
}

###
# Assert that a value is not a key in a hash
###
function _zunit_assert_is_not_key_in() {
  local i found=0 value=$1
  local -A hash
  hash=(${(@)@:2})

  for k v in ${(@kv)hash}; do
    [[ $k = $value ]] && found=1
  done

  [[ $found -eq 0 ]] && return 0

  echo "'$value' is a key in (${(@kv)hash})"
  exit 1
}

###
# Assert that a value is a value in a hash
###
function _zunit_assert_is_value_in() {
  local i found=0 value=$1
  local -A hash
  hash=(${(@)@:2})

  for k v in ${(@kv)hash}; do
    [[ $v = $value ]] && found=1
  done

  [[ $found -eq 1 ]] && return 0

  echo "'$value' is not a value in (${(@kv)hash})"
  exit 1
}

###
# Assert that a value is not a value in a hash
###
function _zunit_assert_is_not_value_in() {
  local i found=0 value=$1
  local -A hash
  hash=(${(@)@:2})

  for k v in ${(@kv)hash}; do
    [[ $v = $value ]] && found=1
  done

  [[ $found -eq 0 ]] && return 0

  echo "'$value' is a value in (${(@kv)hash})"
  exit 1
}

###
# Assert the a path exists
###
function _zunit_assert_exists() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -e "$filepath" ]] && return 0

  echo "'$pathname' does not exist"
  exit 1
}

###
# Assert the a path exists and is a file
###
function _zunit_assert_is_file() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -f "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not a file"
  exit 1
}

###
# Assert the a path exists and is a directory
###
function _zunit_assert_is_dir() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/$pathname"
  else
    filepath="$pathname"
  fi

  [[ -d "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not a directory"
  exit 1
}

###
# Assert the a path exists and is a symbolic link
###
function _zunit_assert_is_link() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -h "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not a symbolic link"
  exit 1
}

###
# Assert the a path exists and is readable
###
function _zunit_assert_is_readable() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -r "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not readable"
  exit 1
}

###
# Assert the a path exists and is writable
###
function _zunit_assert_is_writable() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -w "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not writable"
  exit 1
}

###
# Assert the a path exists and is executable
###
function _zunit_assert_is_executable() {
  local pathname=$1 filepath

  # If filepath is relative, prepend the test directory
  if [[ "${pathname:0:1}" != "/" ]]; then
    filepath="$testdir/${pathname}"
  else
    filepath="$pathname"
  fi

  [[ -x "$filepath" ]] && return 0

  echo "'$pathname' does not exist or is not executable"
  exit 1
}
