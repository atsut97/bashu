#!/usr/bin/env bash

# test_bashu_main.bash
#
# Unit testing for bashu

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

### Utility functions

random_int() {
  local lo hi
  local n=${3:-1}
  case $# in
    0)
      lo=0
      hi=100
      ;;
    1)
      lo=0
      hi=$1
      ;;
    *)
      lo=$1
      hi=$2
      ;;
  esac
  shuf -i "${lo}-${hi}" -n "$n"
}

random_word() {
  local dict=/usr/share/dict/words
  local word="'"
  until [[ "$word" != *"'"* ]]; do
    word=$(shuf -n 1 "$dict")
  done
  echo "$word"
}

getlineno() {
  local filename=$1; shift
  local pattern="$*"'$'

  grep -ne "$pattern" "$filename" | cut -d':' -f1
}

### Constant variables

testcase_self() {
  local expected=$rootdir/bashu

  [ "$bashu_self" == "$expected" ]
}

testcase_rootdir() {
  local expected=$rootdir

  [ "$bashu_rootdir" == "$expected" ]
}

testcase_specfile() {
  local expected=$rootdir/tests/test_bashu_main.bash

  [ "$bashu_specfile" == "$expected" ]
}

### ERR trap handler

testcase_errtrap() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \$r 0  # testcase_errtrap")
  local _output
  local expected="declare -a _err_funcname=([0]=\"testcase_errtrap\"); declare -a _err_source=([0]=\"./test_bashu_main.bash\"); declare -a _err_lineno=([0]=\"$lineno\"); declare -- _err_status=\"$r\";"

  _bashu_errtrap $r 0  # testcase_errtrap
  read -r _output <&$bashu_fd_errtrap
  [ "$_output" == "$expected" ]
}

### Global initializer

# Set random values to mock variables to be uninitialized.
_testcase_initialize_setup() {
  bashu_is_running=$(random_int 10)
  bashu_all_testcases=("testcase_$(random_word)")
  bashu_performed_testcases=("testcase_$(random_word)")
  bashu_passed_testcases=("testcase_$(random_word)")
  bashu_failed_testcases=("testcase_$(random_word)")
  bashu_err_trace_stack=("testcase_$(random_word)")
  bashu_err_trace_stack_aux=("testcase_$(random_word)")
  bashu_err_status_stack=("testcase_$(random_word)")
}

testcase_initialize() {
  # Given that random values are substituted,
  _testcase_initialize_setup
  # When `bashu_initialize` is called,
  bashu_initialize
  # Then variables are initilized.
  [ "$bashu_is_running" -eq 0 ]
  [ ${#bashu_all_testcases[@]} -eq 0 ]
  [ ${#bashu_performed_testcases[@]} -eq 0 ]
  [ ${#bashu_passed_testcases[@]} -eq 0 ]
  [ ${#bashu_failed_testcases[@]} -eq 0 ]
  [ ${#bashu_err_trace_stack[@]} -eq 0 ]
  [ ${#bashu_err_trace_stack_aux[@]} -eq 0 ]
  [ ${#bashu_err_status_stack[@]} -eq 0 ]

  # Check if PID of the formatter is alive.
  ps -p $bashu_pid_formatter >/dev/null

  # File descriptor for test results is also opened.
  : >&$bashu_fd_result
}

### Arguments parser

### Test suite runner

testcase_collect_all_testcases() {
  bashu_all_testcases=()
  bashu_collect_all_testcases "${rootdir}/tests/test_collect_all_testcases.bash"
  [ ${#bashu_all_testcases[@]} -eq 10 ]
  [ "${bashu_all_testcases[0]}" = "testcase_test01" ]
  [ "${bashu_all_testcases[1]}" = "testcase_test02_with_underscore" ]
  [ "${bashu_all_testcases[2]}" = "testcase_test03-with-hyphen" ]
  [ "${bashu_all_testcases[3]}" = "testcase_test04:with:colon" ]
  [ "${bashu_all_testcases[4]}" = "testcase_test05_spaces" ]
  [ "${bashu_all_testcases[5]}" = "testcase_test06" ]
  [ "${bashu_all_testcases[6]}" = "testcase_test07_with_underscore" ]
  [ "${bashu_all_testcases[7]}" = "testcase_test08_spaces" ]
  [ "${bashu_all_testcases[8]}" = "testcase_test09_no_parens" ]
  [ "${bashu_all_testcases[9]}" = "testcase_main" ]
}

testcase_begin_test_suite() {
  bashu_initialize
  [ "$bashu_is_running" -eq 0 ]
  bashu_begin_test_suite
  [ "$bashu_is_running" -eq 1 ]
  : >&$bashu_fd_errtrap
}

testcase_finish_test_suite() {
  bashu_finish_test_suite
  [ "$bashu_is_running" -eq 0 ]
  ! (: >&$bashu_fd_errtrap) 2>/dev/null
}

testcase_dump_summary() {
  # Setup
  bashu_is_running=0
  bashu_all_testcases=()
  bashu_performed_testcases=()
  bashu_passed_testcases=()
  bashu_failed_testcases=()

  # Set random values
  local n=$(( RANDOM % 10 + 5 ))
  for ((i=0; i<n; i++)); do
    bashu_all_testcases+=("testcase_$(random_word)")
  done
  bashu_performed_testcases=("${bashu_all_testcases[@]:0:$((n-1))}")
  bashu_passed_testcases=("${bashu_performed_testcases[@]:0:$((n-3))}")
  bashu_failed_testcases=("${bashu_performed_testcases[@]:$((n-3)):2}")

  # Test code
  local fd
  local _output
  local expected="declare -- _bashu_is_running=\"0\"; "
  expected+="$(declare -p bashu_all_testcases | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_performed_testcases | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_passed_testcases | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_failed_testcases | sed 's/\(\w\+\)=/_\1=/');"

  exec {fd}<> <(:)
  bashu_dump_summary "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]
  exec {fd}>&-
}

### Test case runner

_testcase_preprocess_setup() {
  bashu_current_test="testcase_$(random_word)"
  bashu_is_failed=$(random_int 10)
  bashu_err_funcname=("testcase_$(random_word)")
  bashu_err_source=("test_$(random_word).bash")
  bashu_err_lineno=("$(random_int 100)")
  bashu_err_status=$(random_int 10)
}

testcase_preprocess() {
  # Given that random values are substituted,
  _testcase_preprocess_setup
  # When `bashu_preprocess` is called,
  bashu_preprocess "testcase_test"
  # Then variables are initilized.
  [ "$bashu_current_test" == "testcase_test" ]
  [ "$bashu_is_failed" -eq 0 ]
  [ ${#bashu_err_funcname[@]} -eq 0 ]
  [ ${#bashu_err_source[@]} -eq 0 ]
  [ ${#bashu_err_lineno[@]} -eq 0 ]
  [ -z "$bashu_err_status" ]
}

_testcase_postprocess_setup() {
  bashu_performed_testcases=()
  bashu_passed_testcases=()
  bashu_failed_testcases=()
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()
}

testcase_postprocess_when_success() {
  _testcase_postprocess_setup
  bashu_postprocess 0
  [ "${bashu_performed_testcases[0]}" == "${FUNCNAME[0]}" ]
  [ "${bashu_passed_testcases[0]}" == "${FUNCNAME[0]}" ]
  [ "${#bashu_failed_testcases[@]}" -eq 0 ]
}

testcase_postprocess_when_failure() {
  _testcase_postprocess_setup
  _bashu_errtrap 10
  bashu_postprocess 10
  [ "$bashu_is_failed" -eq 1 ]
  [ "$bashu_err_status" -eq 10 ]
  [ "${bashu_performed_testcases[0]}" == "${FUNCNAME[0]}" ]
  [ "${#bashu_passed_testcases[@]}" -eq 0 ]
  [ "${bashu_failed_testcases[0]}" == "${FUNCNAME[0]}" ]
}

testcase_postprocess_when_failure_err_stack() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \$r 0  # testcase_postprocess_when_failure_err_stack")
  local expected="testcase_postprocess_when_failure_err_stack:./test_bashu_main.bash:$lineno"

  _testcase_postprocess_setup
  _bashu_errtrap $r 0  # testcase_postprocess_when_failure_err_stack
  bashu_postprocess $r
  [ "${#bashu_err_trace_stack[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1" ]

  [ "${#bashu_err_status_stack[@]}" -eq 1 ]
  [ "${bashu_err_status_stack[*]}" == "$r" ]
}

testcase_postprocess_when_failure_err_stack2() {
  local r=$(( RANDOM % 10 + 1 ))
  local r2=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \$r 0  # testcase_postprocess_when_failure_err_stack2")
  lineno2=$(getlineno "$0" "_bashu_errtrap \$r2 0  # testcase_postprocess_when_failure_err_stack2")
  local expected="testcase_postprocess_when_failure_err_stack2:./test_bashu_main.bash:$lineno"
  local expected2="testcase_postprocess_when_failure_err_stack2:./test_bashu_main.bash:$lineno2"

  _testcase_postprocess_setup
  _bashu_errtrap $r 0  # testcase_postprocess_when_failure_err_stack2
  _bashu_errtrap $r2 0  # testcase_postprocess_when_failure_err_stack2
  bashu_postprocess $r
  bashu_postprocess $r2

  [ "${#bashu_err_trace_stack[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected $expected2" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1 1" ]

  [ "${#bashu_err_status_stack[@]}" -eq 2 ]
  [ "${bashu_err_status_stack[*]}" == "$r $r2" ]
}

_testcase_postprocess_when_failure_err_stack_nested() {
  local r=$1
  _bashu_errtrap "$r" 0  # _testcase_postprocess_when_failure_err_stack_nested
}

testcase_postprocess_when_failure_err_stack_nested() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" 0  # _testcase_postprocess_when_failure_err_stack_nested")
  lineno2=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested \$r")
  local expected="_testcase_postprocess_when_failure_err_stack_nested:./test_bashu_main.bash:$lineno testcase_postprocess_when_failure_err_stack_nested:./test_bashu_main.bash:$lineno2"

  _testcase_postprocess_setup
  _testcase_postprocess_when_failure_err_stack_nested $r
  bashu_postprocess $r

  [ "${#bashu_err_trace_stack[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "2" ]

  [ "${#bashu_err_status_stack[@]}" -eq 1 ]
  [ "${bashu_err_status_stack[*]}" == "$r" ]
}

_testcase_postprocess_when_failure_err_stack_nested2() {
  local r=$1
  _bashu_errtrap "$r" 0  # _testcase_postprocess_when_failure_err_stack_nested2
}

testcase_postprocess_when_failure_err_stack_nested2() {
  local r=$(( RANDOM % 10 + 1 ))
  local r2=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" 0  # _testcase_postprocess_when_failure_err_stack_nested2")
  lineno2=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested2 \$r")
  lineno3=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested2 \$r2")
  local expected_arr=("_testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno" "testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno2" "_testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno" "testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno3")

  _testcase_postprocess_setup
  _testcase_postprocess_when_failure_err_stack_nested2 $r
  bashu_postprocess $r
  _testcase_postprocess_when_failure_err_stack_nested2 $r2
  bashu_postprocess $r2

  [ "${#bashu_err_trace_stack[@]}" -eq 4 ]
  [ "${bashu_err_trace_stack[*]}" == "${expected_arr[*]}" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "2 2" ]

  [ "${#bashu_err_status_stack[@]}" -eq 2 ]
  [ "${bashu_err_status_stack[*]}" == "$r $r2" ]
}

testcase_dump_result_when_success() {
  local _output
  local expected="declare -- _bashu_is_running=\"1\"; declare -- _bashu_current_test=\"testcase_dump_result_when_success\"; declare -- _bashu_is_failed=\"0\";"
  local fd

  # Open FD for testing.
  exec {fd}<> <(:)

  bashu_dump_result "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]

  # Close FD.
  exec {fd}>&-
}

testcase_dump_result_when_failure() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \$r 0  # testcase_dump_result_when_failure")
  local _output
  local expected="declare -- _bashu_is_running=\"1\"; declare -- _bashu_current_test=\"testcase_dump_result_when_failure\"; declare -- _bashu_is_failed=\"1\"; declare -a _bashu_err_funcname=([0]=\"testcase_dump_result_when_failure\"); declare -a _bashu_err_source=([0]=\"./test_bashu_main.bash\"); declare -a _bashu_err_lineno=([0]=\"$lineno\"); declare -- _bashu_err_status=\"$r\";"
  local fd

  # Open FD for testing.
  exec {fd}<> <(:)

  _testcase_postprocess_setup
  _bashu_errtrap $r 0  # testcase_dump_result_when_failure
  bashu_postprocess $r
  bashu_dump_result "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]

  # Close FD.
  exec {fd}>&-
}

bashu_main "$@"
