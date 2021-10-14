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

declare -i fd

setup() {
  exec {fd}<> <(:)
}

teardown() {
  [[ ! -t $fd ]] && exec {fd}>&-
}

testcase_errtrap() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_errtrap")
  local _output
  local expected="declare -a _err_funcname=([0]=\"testcase_errtrap\"); declare -a _err_source=([0]=\"./test_bashu_main.bash\"); declare -a _err_lineno=([0]=\"$lineno\"); declare -- _err_status=\"$r\";"

  setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_errtrap
  read -r _output <&"$fd"
  [ "$_output" == "$expected" ]
  teardown
}

### Global initializer

# Set random values to mock variables to be uninitialized.
_testcase_initialize_setup() {
  bashu_is_running=$(random_int 10)
  bashu_collected_testcases=("testcase_$(random_word)")
  bashu_scheduled_testcases=("testcase_$(random_word)")
  bashu_testcase_results=("$(random_int 4)")
  bashu_execution_time=("$(random_int 300)")
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
  [ ${#bashu_collected_testcases[@]} -eq 0 ]
  [ ${#bashu_scheduled_testcases[@]} -eq 0 ]
  [ ${#bashu_testcase_results[@]} -eq 0 ]
  [ ${#bashu_execution_time[@]} -eq 0 ]
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
  bashu_collected_testcases=()
  bashu_collect_all_testcases "${rootdir}/tests/test_collect_all_testcases.bash"
  [ ${#bashu_collected_testcases[@]} -eq 10 ]
  [ "${bashu_collected_testcases[0]}" = "testcase_test01" ]
  [ "${bashu_collected_testcases[1]}" = "testcase_test02_with_underscore" ]
  [ "${bashu_collected_testcases[2]}" = "testcase_test03-with-hyphen" ]
  [ "${bashu_collected_testcases[3]}" = "testcase_test04:with:colon" ]
  [ "${bashu_collected_testcases[4]}" = "testcase_test05_spaces" ]
  [ "${bashu_collected_testcases[5]}" = "testcase_test06" ]
  [ "${bashu_collected_testcases[6]}" = "testcase_test07_with_underscore" ]
  [ "${bashu_collected_testcases[7]}" = "testcase_test08_spaces" ]
  [ "${bashu_collected_testcases[8]}" = "testcase_test09_no_parens" ]
  [ "${bashu_collected_testcases[9]}" = "testcase_main" ]
}

testcase_begin_test_suite() {
  bashu_initialize
  __timer_start_stack=()
  [ "$bashu_is_running" -eq 0 ]
  [ "${#__timer_start_stack[@]}" -eq 0 ]
  bashu_begin_test_suite
  [ "$bashu_is_running" -eq 1 ]
  [ "${#__timer_start_stack[@]}" -eq 1 ]
  : >&$bashu_fd_errtrap
}

testcase_finish_test_suite() {
  __timer_start_stack=("$(date +%s%3N)")
  bashu_finish_test_suite
  [ "${#__timer_start_stack[@]}" -eq 0 ]
  [ -n "${bashu_total_execution_time##*[!0-9]*}" ]
  [ "$bashu_is_running" -eq 0 ]
  ! (: >&$bashu_fd_errtrap) 2>/dev/null
}

testcase_dump_summary() {
  # Setup
  bashu_is_running=0
  bashu_collected_testcases=()
  bashu_testcase_results=()
  bashu_execution_time=()
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()
  _total_execution_time=$(random_int 1000)

  # Set random values
  local n=$(( RANDOM % 10 + 5 ))
  local r=$(( RANDOM % 3 + 1 ))
  for ((i=0; i<n; i++)); do
    bashu_collected_testcases+=("testcase_$(random_word)")
    bashu_scheduled_testcases+=("$i")
  done
  for ((i=0; i<n-3; i++)); do
    bashu_testcase_results+=("$bashu_testcase_result_passed")
  done
  for ((i=n-3; i<2; i++)); do
    bashu_testcase_results+=("$bashu_testcase_result_failed")
  done
  for ((i=0; i<n-1; i++)); do
    bashu_execution_time+=("$(random_int 400)")
  done
  bashu_execution_time+=("0")
  bashu_total_execution_time="$_total_execution_time"
  bashu_err_trace_stack=(
    "testcase_$(random_word):func_$(random_word):${BASH_SOURCE[0]}:$(random_int 10 100)"
  )
  for ((i=0; i<r; i++)); do
    bashu_err_trace_stack+=(
      "testcase_$(random_word):func_$(random_word):${BASH_SOURCE[0]}:$(random_int $((i*100)) $((i*100+100)))"
    )
  done
  bashu_err_trace_stack_aux=("1" "$r")
  bashu_err_status_stack=("$(random_int 1 10)" "$(random_int 1 10)")

  # Test code
  local fd
  local _output
  local expected="declare -- _bashu_is_running=\"0\"; "
  expected+="$(declare -p bashu_collected_testcases | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_scheduled_testcases | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_testcase_results | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_execution_time | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="declare -- _bashu_total_execution_time=\"$_total_execution_time\"; "
  expected+="$(declare -p bashu_err_trace_stack | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_err_trace_stack_aux | sed 's/\(\w\+\)=/_\1=/'); "
  expected+="$(declare -p bashu_err_status_stack | sed 's/\(\w\+\)=/_\1=/');"

  setup
  bashu_dump_summary "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]
  teardown
}

### Test case runner

_testcase_err_trace_stack_setup() {
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
}

testcase_err_trace_stack_add() {
  local expected

  _testcase_err_trace_stack_setup

  # Create the first dummy error trace elements.
  bashu_current_test="testcase_$(random_word)"
  bashu_err_funcname=("$bashu_current_test")
  bashu_err_source=("test_$(random_word).bash")
  bashu_err_lineno=("$(random_int 100)")
  # Add the error trace to the stack.
  bashu_err_trace_stack_add
  # Check the added error trace elements.
  expected="${bashu_current_test}:${bashu_err_funcname[0]}:${bashu_err_source[0]}:${bashu_err_lineno[0]}"
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1" ]

  # Create the second dummy error trace elements.
  bashu_current_test="testcase_$(random_word)"
  bashu_err_funcname=("func_$(random_word)" "$bashu_current_test")
  bashu_err_source=("test_$(random_word).bash" "test_$(random_word).bash")
  bashu_err_lineno=("$(random_int 100 200)" "$(random_int 100 200)")
  # Add the error trace to the stack.
  bashu_err_trace_stack_add
  # Check the added error trace elements.
  expected+=" ${bashu_current_test}:${bashu_err_funcname[1]}:${bashu_err_source[1]}:${bashu_err_lineno[1]}\
 ${bashu_current_test}:${bashu_err_funcname[0]}:${bashu_err_source[0]}:${bashu_err_lineno[0]}"
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1 2" ]

  # Create the third dummy error trace elements.
  bashu_current_test="testcase_$(random_word)"
  bashu_err_funcname=("func_$(random_word)" "func_$(random_word)" "$bashu_current_test")
  bashu_err_source=("test_$(random_word).bash" "test_$(random_word).bash" "test_$(random_word).bash")
  bashu_err_lineno=("$(random_int 200 300)" "$(random_int 200 300)" "$(random_int 200 300)")
  # Add the error trace to the stack.
  bashu_err_trace_stack_add
  # Check the added error trace elements.
  expected+=" ${bashu_current_test}:${bashu_err_funcname[2]}:${bashu_err_source[2]}:${bashu_err_lineno[2]}\
 ${bashu_current_test}:${bashu_err_funcname[1]}:${bashu_err_source[1]}:${bashu_err_lineno[1]}\
 ${bashu_current_test}:${bashu_err_funcname[0]}:${bashu_err_source[0]}:${bashu_err_lineno[0]}"
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1 2 3" ]
}

_testcase_err_trace_stack_get_add_stack() {
  local n=$1 i
  local err_trace=()
  local err_trace_=()

  bashu_current_test="testcase_$(random_word)"
  bashu_err_funcname=()
  bashu_err_source=()
  bashu_err_lineno=()
  for ((i=0; i<n; i++)); do
    if ((i == n-1)); then
      bashu_err_funcname+=("${bashu_current_test}")
    else
      bashu_err_funcname+=("func_$(random_word)")
    fi
    bashu_err_source+=("test_$(random_word).bash")
    bashu_err_lineno+=("$(random_int 100)")
    err_trace+=("${bashu_current_test}:${bashu_err_funcname[-1]}:${bashu_err_source[-1]}:${bashu_err_lineno[-1]}")
  done
  # Reverse order.
  for ((i=$((n-1)); i>=0; i--)); do
    err_trace_+=("${err_trace[$i]}")
  done
  bashu_err_trace_stack_add
  eval "$2=(\"\${err_trace_[@]}\")"
}

testcase_err_trace_stack_get() {
  local r
  local err_trace=()

  # Expected values
  local err_trace1=()
  local err_trace2=()
  local err_trace3=()
  local err_trace4=()

  _testcase_err_trace_stack_setup

  # Create dummy error trace stack.
  r=$(random_int 1 4)
  _testcase_err_trace_stack_get_add_stack "$r" "err_trace1"
  r=$(random_int 1 4)
  _testcase_err_trace_stack_get_add_stack "$r" "err_trace2"
  r=$(random_int 1 4)
  _testcase_err_trace_stack_get_add_stack "$r" "err_trace3"
  r=$(random_int 1 4)
  _testcase_err_trace_stack_get_add_stack "$r" "err_trace4"

  bashu_current_test="${FUNCNAME[0]}"
  # Check if error trace can be retrieved.
  bashu_err_trace_stack_get 0 err_trace
  [ "${err_trace[*]}" == "${err_trace1[*]}" ]
  bashu_err_trace_stack_get 1 err_trace
  [ "${err_trace[*]}" == "${err_trace2[*]}" ]
  bashu_err_trace_stack_get 2 err_trace
  [ "${err_trace[*]}" == "${err_trace3[*]}" ]
  bashu_err_trace_stack_get 3 err_trace
  [ "${err_trace[*]}" == "${err_trace4[*]}" ]
}

_testcase_preprocess_setup() {
  bashu_current_test="testcase_$(random_word)"
  bashu_is_failed=$(random_int 10)
  bashu_err_funcname=("testcase_$(random_word)")
  bashu_err_source=("test_$(random_word).bash")
  bashu_err_lineno=("$(random_int 100)")
  bashu_err_status=$(random_int 10)
  __timer_start_stack=("$(date +%s%3N)")
}

testcase_preprocess() {
  # Given that random values are substituted,
  _testcase_preprocess_setup
  # When `bashu_preprocess` is called,
  bashu_preprocess "${FUNCNAME[0]}"
  # Then variables are initilized.
  [ "$bashu_current_test" == "${FUNCNAME[0]}" ]
  [ "$bashu_is_failed" -eq 0 ]
  [ ${#bashu_err_funcname[@]} -eq 0 ]
  [ ${#bashu_err_source[@]} -eq 0 ]
  [ ${#bashu_err_lineno[@]} -eq 0 ]
  [ -z "$bashu_err_status" ]
  # Check if a timer is started.
  [ "${#__timer_start_stack[@]}" -eq 2 ]
  [ "${__timer_start_stack[1]}" -gt 0 ]
}

_testcase_postprocess_setup() {
  bashu_testcase_results=()
  __timer_start_stack=("$(date +%s%3N)" "$(date +%s%3N)")
  bashu_execution_time=()
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()
}

testcase_postprocess_when_success() {
  _testcase_postprocess_setup
  bashu_postprocess 0
  [ "$(declare -p bashu_testcase_results)" == "declare -a bashu_testcase_results=([0]=\"${bashu_testcase_result_passed}\")" ]
  [ "${#bashu_execution_time[@]}" -eq 1 ]
  [ -n "${bashu_execution_time[0]##*[!0-9]*}" ]
}

testcase_postprocess_when_failure() {
  setup
  _testcase_postprocess_setup
  _bashu_errtrap 10 "$fd"
  bashu_postprocess 10 "$fd"
  [ "$bashu_is_failed" -eq 1 ]
  [ "$bashu_err_status" -eq 10 ]
  [ "$(declare -p bashu_testcase_results)" == \
    "declare -a bashu_testcase_results=([0]=\"${bashu_testcase_result_failed}\")" ]
  [ "${#bashu_execution_time[@]}" -eq 1 ]
  [ -n "${bashu_execution_time[0]##*[!0-9]*}" ]
  teardown
}

testcase_postprocess_when_failure_err_stack() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_postprocess_when_failure_err_stack")
  local expected="testcase_postprocess_when_failure_err_stack:testcase_postprocess_when_failure_err_stack:./test_bashu_main.bash:$lineno"

  setup
  _testcase_postprocess_setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_postprocess_when_failure_err_stack
  bashu_postprocess "$r" "$fd"
  [ "${#bashu_err_trace_stack[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1" ]

  [ "${#bashu_err_status_stack[@]}" -eq 1 ]
  [ "${bashu_err_status_stack[*]}" == "$r" ]
  teardown
}

testcase_postprocess_when_failure_err_stack2() {
  local r=$(( RANDOM % 10 + 1 ))
  local r2=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_postprocess_when_failure_err_stack2")
  lineno2=$(getlineno "$0" "_bashu_errtrap \"\$r2\" \"\$fd\" 0 # testcase_postprocess_when_failure_err_stack2")
  local expected="testcase_postprocess_when_failure_err_stack2:testcase_postprocess_when_failure_err_stack2:./test_bashu_main.bash:$lineno"
  local expected2="testcase_postprocess_when_failure_err_stack2:testcase_postprocess_when_failure_err_stack2:./test_bashu_main.bash:$lineno2"

  setup
  _testcase_postprocess_setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_postprocess_when_failure_err_stack2
  _bashu_errtrap "$r2" "$fd" 0 # testcase_postprocess_when_failure_err_stack2
  bashu_postprocess "$r" "$fd"
  bashu_postprocess "$r2" "$fd"

  [ "${#bashu_err_trace_stack[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected $expected2" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "1 1" ]

  [ "${#bashu_err_status_stack[@]}" -eq 2 ]
  [ "${bashu_err_status_stack[*]}" == "$r $r2" ]
  teardown
}

_testcase_postprocess_when_failure_err_stack_nested() {
  local r=$1
  _bashu_errtrap "$r" "$fd" 0 # _testcase_postprocess_when_failure_err_stack_nested
}

testcase_postprocess_when_failure_err_stack_nested() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # _testcase_postprocess_when_failure_err_stack_nested")
  lineno2=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested \$r")
  local expected="testcase_postprocess_when_failure_err_stack_nested:testcase_postprocess_when_failure_err_stack_nested:./test_bashu_main.bash:$lineno2 testcase_postprocess_when_failure_err_stack_nested:_testcase_postprocess_when_failure_err_stack_nested:./test_bashu_main.bash:$lineno"

  setup
  _testcase_postprocess_setup
  _testcase_postprocess_when_failure_err_stack_nested $r
  bashu_postprocess "$r" "$fd"

  [ "${#bashu_err_trace_stack[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack[*]}" == "$expected" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 1 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "2" ]

  [ "${#bashu_err_status_stack[@]}" -eq 1 ]
  [ "${bashu_err_status_stack[*]}" == "$r" ]
  teardown
}

_testcase_postprocess_when_failure_err_stack_nested2() {
  local r=$1
  _bashu_errtrap "$r" "$fd" 0 # _testcase_postprocess_when_failure_err_stack_nested2
}

testcase_postprocess_when_failure_err_stack_nested2() {
  local r=$(( RANDOM % 10 + 1 ))
  local r2=$(( RANDOM % 10 + 1 ))
  local lineno
  local lineno2
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # _testcase_postprocess_when_failure_err_stack_nested2")
  lineno2=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested2 \$r")
  lineno3=$(getlineno "$0" "_testcase_postprocess_when_failure_err_stack_nested2 \$r2")
  local expected_arr=(
    "testcase_postprocess_when_failure_err_stack_nested2:testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno2"
    "testcase_postprocess_when_failure_err_stack_nested2:_testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno"
    "testcase_postprocess_when_failure_err_stack_nested2:testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno3"
    "testcase_postprocess_when_failure_err_stack_nested2:_testcase_postprocess_when_failure_err_stack_nested2:./test_bashu_main.bash:$lineno"
  )

  setup
  _testcase_postprocess_setup
  _testcase_postprocess_when_failure_err_stack_nested2 $r
  bashu_postprocess "$r" "$fd"
  _testcase_postprocess_when_failure_err_stack_nested2 $r2
  bashu_postprocess "$r2" "$fd"

  [ "${#bashu_err_trace_stack[@]}" -eq 4 ]
  [ "${bashu_err_trace_stack[*]}" == "${expected_arr[*]}" ]

  [ "${#bashu_err_trace_stack_aux[@]}" -eq 2 ]
  [ "${bashu_err_trace_stack_aux[*]}" == "2 2" ]

  [ "${#bashu_err_status_stack[@]}" -eq 2 ]
  [ "${bashu_err_status_stack[*]}" == "$r $r2" ]
  teardown
}

testcase_dump_result_when_success() {
  local _output
  local expected="declare -- _bashu_is_running=\"1\"; declare -- _bashu_current_test=\"testcase_dump_result_when_success\"; declare -- _bashu_is_failed=\"0\";"

  setup
  bashu_dump_result "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]
  teardown
}

testcase_dump_result_when_failure() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_dump_result_when_failure")
  local _output
  local expected="declare -- _bashu_is_running=\"1\"; declare -- _bashu_current_test=\"testcase_dump_result_when_failure\"; declare -- _bashu_is_failed=\"1\"; declare -a _bashu_err_funcname=([0]=\"testcase_dump_result_when_failure\"); declare -a _bashu_err_source=([0]=\"./test_bashu_main.bash\"); declare -a _bashu_err_lineno=([0]=\"$lineno\"); declare -- _bashu_err_status=\"$r\";"

  setup
  _testcase_postprocess_setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_dump_result_when_failure
  bashu_postprocess "$r" "$fd"
  bashu_dump_result "$fd"
  read -r -t 0.1 _output <&"$fd"
  [ "$_output" == "$expected" ]
  teardown
}

bashu_main "$@"
