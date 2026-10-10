function calculator_add() {
  local a=$1 b=$2
  echo $(( a + b ))
}

function calculator_subtract() {
  local a=$1 b=$2
  echo $(( a - b ))
}
