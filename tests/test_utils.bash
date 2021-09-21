#!/bin/bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

# shellcheck disable=SC2034
testcase_print_vars() {
  var1="hello"
  var2="world"
  var3="!"

  output=$(print_var_defs "var1" "var2" "var3")
  [ "$output" == "declare -- _var1=\"hello\"; declare -- _var2=\"world\"; declare -- _var3=\"!\"; " ]
}

# shellcheck disable=SC2034
testcase_print_vars_array() {
  array=("hello" "world" "!")

  output=$(print_var_defs "array")
  [ "$output" == "declare -a _array=([0]=\"hello\" [1]=\"world\" [2]=\"!\"); " ]
}

# shellcheck disable=SC2034
testcase_print_vars_associative_array() {
  declare -A dict
  dict[e01]="hello"
  dict[e02]="world"
  dict[e03]="!"

  output=$(print_var_defs "dict")
  [ "$output" == "declare -A _dict=([e01]=\"hello\" [e03]=\"!\" [e02]=\"world\" ); " ]
}

# shellcheck disable=SC2034
testcase_print_integars() {
  declare -i int1
  declare -i int2
  declare -i int3
  int1=0
  int2=1
  int3=2

  output=$(print_var_defs "int1" "int2" "int3")
  [ "$output" == "declare -i _int1=\"0\"; declare -i _int2=\"1\"; declare -i _int3=\"2\"; " ]
}

dummy_f() {
  echo "$@"
}

testcase_copy_function() {
  copy_function dummy_f dummy_g
  s=$(dummy_g "hello world !")
  [ "$s" == "hello world !" ]
}

testcase_copy_function_return_failure() {
  s=0
  copy_function non_exist_function dummy_g || s=$?
  [ $s -eq 1 ]
}

bashu_main "$@"
