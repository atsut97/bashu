#!/bin/bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

declare -i fd

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

  grep -ne "$pattern" "$filename" | head -1 | cut -d':' -f1
}

setup() {
  exec {fd}<> <(:)
}

teardown() {
  [[ ! -t $fd ]] && exec {fd}>&-
}

backup_var() {
  local v
  v="$(declare -p "$1" | sed -e "s/$1=/_$1=/" -e "s/declare /declare -g /")" \
    && eval "$v"
}

backup() {
  backup_var bashu_is_running
  backup_var bashu_current_test
  backup_var bashu_is_failed
  backup_var bashu_err_funcname
  backup_var bashu_err_source
  backup_var bashu_err_lineno
  backup_var bashu_collected_testcases
  backup_var bashu_testcase_results
  backup_var bashu_err_trace_stack
  backup_var bashu_err_trace_stack_aux
  backup_var bashu_err_status_stack
}

fuzz() {
  local r
  backup
  bashu_is_running=$(random_int 10)
  bashu_is_failed=$(random_int 10)
  bashu_err_funcname=()
  bashu_err_source=()
  bashu_err_lineno=()
  bashu_collected_testcases=()
  bashu_testcase_results=()
  bashu_total_execution_time=0
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()
  r=$(random_int 1 4)
  for (( i=0; i<r; i++ )); do
    bashu_err_funcname+=("func_$(random_word)")
    bashu_err_source+=("source_$(random_word)")
    bashu_err_lineno+=("$(random_int 500)")
    bashu_collected_testcases+=("testcase_$(random_word)")
    bashu_testcase_results+=("$(random_int 3)")
    bashu_err_trace_stack+=("$(random_word)")
    bashu_err_trace_stack_aux+=("$(random_int 10)")
    bashu_err_status_stack+=("$(random_int 10)")
  done
  bashu_total_execution_time=$(random_int 1 1000)
  bashu_err_status=$(random_int 10)
}

testcase_formatter_result_default_when_success() {
  setup
  bashu_is_running=1
  bashu_current_test="${FUNCNAME[0]}"
  bashu_is_failed=0

  bashu_dump_result "$fd"
  fuzz
  read -r -u "$fd" v; eval "$v"
  _bashu_formatter_default "$fd" >/dev/null
  [ "$bashu_is_running" -eq 1 ]
  [ "$bashu_current_test" == "${FUNCNAME[0]}" ]
  [ "$bashu_is_failed" -eq 0 ]
  teardown
}

testcase_formatter_result_default_when_success_output() {
  local _output

  setup
  bashu_is_running=1
  bashu_current_test="${FUNCNAME[0]}"
  bashu_is_failed=0

  bashu_dump_result "$fd"
  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"
  [ "$_output" == "^[[32m.^[[m^O" ]
  teardown
}

testcase_formatter_result_default_when_failure() {
  local r=$(( RANDOM % 10 + 1 ))
  local lineno
  lineno=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_formatter_result_default_when_failure")

  setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_formatter_result_default_when_failure
  bashu_postprocess "$r" "$fd"
  bashu_dump_result "$fd"

  fuzz
  read -r -u "$fd" v; eval "$v"
  _bashu_formatter_default "$fd" >/dev/null
  [ "$bashu_is_running" -eq 1 ]
  [ "$bashu_current_test" == "${FUNCNAME[0]}" ]
  [ "$bashu_is_failed" -eq 1 ]
  [ "${bashu_err_funcname[*]}" == "${FUNCNAME[0]}" ]
  [ "${bashu_err_source[*]}" == "$0" ]
  [ "${bashu_err_lineno[*]}" == "$lineno" ]
  [ "$bashu_err_status" -eq $r ]
  teardown
}

testcase_formatter_result_default_when_failure_output() {
  local _output
  local r=$(( RANDOM % 10 + 1 ))

  setup
  _bashu_errtrap "$r" "$fd" 0 # testcase_formatter_result_default_when_failure_output
  bashu_postprocess "$r" "$fd"
  bashu_dump_result "$fd"

  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"
  [ "$_output" == "^[[31mF^[[m^O" ]
  teardown
}

# shellcheck disable=SC2154
testcase_formatter_summary_default_when_success() {
  bashu_is_running=0
  bashu_collected_testcases=("testcase_$(random_word)")
  bashu_testcase_results=("$bashu_testcase_result_passed")
  bashu_total_execution_time=$(random_int 1 1000)
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()

  setup
  bashu_dump_summary "$fd"
  fuzz
  read -r -u "$fd" v; eval "$v"
  _bashu_formatter_default "$fd" >/dev/null
  [ "$bashu_is_running" -eq 0 ]
  [ "${bashu_collected_testcases[*]}" == "${_bashu_collected_testcases[*]}" ]
  [ "${bashu_testcase_results[*]}" == "${bashu_testcase_results[*]}" ]
  [ "${bashu_total_execution_time}" == "${_bashu_total_execution_time}" ]
  [ "${bashu_err_trace_stack[*]}" == "${_bashu_err_trace_stack[*]}" ]
  [ "${bashu_err_trace_stack_aux[*]}" == "${_bashu_err_trace_stack_aux[*]}" ]
  [ "${bashu_err_status_stack[*]}" == "${_bashu_err_status_stack[*]}" ]
  teardown
}

testcase_formatter_summary_default_when_success_rand() {
  local r

  r=$(random_int 1 5)
  bashu_is_running=0
  bashu_collected_testcases=()
  for ((i=0; i<r; i++)); do
    bashu_collected_testcases+=("testcase_$(random_word)")
  done
  bashu_testcase_results=()
  for ((i=0; i<r; i++)); do
    bashu_testcase_results+=("$bashu_testcase_result_passed")
  done
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()

  setup
  bashu_dump_summary "$fd"
  fuzz
  read -r -u "$fd" v; eval "$v"
  _bashu_formatter_default "$fd" >/dev/null
  [ "$bashu_is_running" -eq 0 ]
  [ "${bashu_collected_testcases[*]}" == "${_bashu_collected_testcases[*]}" ]
  [ "${bashu_testcase_results[*]}" == "${bashu_testcase_results[*]}" ]
  [ "${bashu_total_execution_time}" == "${_bashu_total_execution_time}" ]
  [ "${bashu_err_trace_stack[*]}" == "${_bashu_err_trace_stack[*]}" ]
  [ "${bashu_err_trace_stack_aux[*]}" == "${_bashu_err_trace_stack_aux[*]}" ]
  [ "${bashu_err_status_stack[*]}" == "${_bashu_err_status_stack[*]}" ]
  teardown
}

testcase_formatter_summary_default_when_success_output() {
  local _output
  local expected=$'\n'"^[[1m^[[32m1 passed^[[m^O^[[32m in 0.01s^[[m^O"

  bashu_is_running=0
  bashu_collected_testcases=("testcase_$(random_word)")
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()

  setup
  bashu_total_execution_time="10"
  bashu_dump_summary "$fd"
  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"
  [ "$_output" == "$expected" ]
  teardown
}

testcase_formatter_summary_default_when_success_output_rand() {
  local _output
  local expected
  local r

  r=$(random_int 1 5)
  bashu_is_running=0
  bashu_collected_testcases=()
  for ((i=0; i<r; i++)); do
    bashu_collected_testcases+=("testcase_$(random_word)")
  done
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()

  setup
  bashu_total_execution_time="${r}0"
  bashu_dump_summary "$fd"
  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"
  expected=$'\n'"^[[1m^[[32m$r passed^[[m^O^[[32m in 0.0${r}s^[[m^O"
  [ "$_output" == "$expected" ]
  teardown
}

series_of_malicious_commands() {
  local hoge=1
  local fuga=2
  local str="hello world"

  [ "$hoge" -eq 13 ]
  [ $fuga -eq 33 ]
  [ "$str" == "HELLO WORLD" ]

  [ $((hoge + fuga)) -eq 124 ] # comment
  [ -z "$hoge" ] # comment # comment2

  false "this" "is" "a" \
        "long" "command"
  false "this" "is" "also" "a" \  # comment
        "very" "very" "long" \
        "command"

  [   $((hoge+fuga))   -eq   11  ]
  [   $(( hoge  +  fuga ))  -eq  13  ]
}

testcase_formatter_normalize_command() {
  local source="$0"
  local lineno
  local _output
  local expected

  # Case 1
  lineno=$(getlineno "$0" "\[ \"\$hoge\" -eq 13 \]")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \"\$hoge\" -eq 13 ]"
  [ "$_output" == "$expected" ]

  # Case 2
  lineno=$(getlineno "$0" "\[ \$fuga -eq 33 \]")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \$fuga -eq 33 ]"
  [ "$_output" == "$expected" ]

  # Case 3
  lineno=$(getlineno "$0" "\[ \"\$str\" == \"HELLO WORLD\" \]")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \"\$str\" == \"HELLO WORLD\" ]"
  [ "$_output" == "$expected" ]
}

testcase_formatter_normalize_command_comment() {
  local source="$0"
  local lineno
  local _output
  local expected

  # Case 1
  lineno=$(getlineno "$0" "\[ \$((hoge + fuga)) -eq 124 \] # comment")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \$((hoge + fuga)) -eq 124 ]"
  [ "$_output" == "$expected" ]

 # Case 2
  lineno=$(getlineno "$0" "\[ -z \"\$hoge\" \] # comment # comment2")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ -z \"\$hoge\" ]"
  [ "$_output" == "$expected" ]
}

testcase_formatter_normalize_command_backslash() {
  local source="$0"
  local lineno
  local _output
  local expected

  # Case 1
  lineno=$(getlineno "$0" "false \"this\" \"is\" \"a\" \\\\")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="false \"this\" \"is\" \"a\""
  [ "$_output" == "$expected" ]

  # Case 2
  lineno=$(getlineno "$0" "false \"this\" \"is\" \"also\" \"a\" \\\\  # comment")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="false \"this\" \"is\" \"also\" \"a\""
  [ "$_output" == "$expected" ]
}

testcase_formatter_normalize_command_spaces_between_args() {
  local source="$0"
  local lineno
  local _output
  local expected

  # Case 1
  lineno=$(getlineno "$0" "\[   \$((hoge+fuga))   -eq   11  \]")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \$((hoge+fuga)) -eq 11 ]"
  [ "$_output" == "$expected" ]

  # Case 2
  lineno=$(getlineno "$0" "\[   \$(( hoge  +  fuga ))  -eq  13  \]")
  _output=$(_bashu_formatter_normalize_command "$source" "$lineno")
  expected="[ \$(( hoge + fuga )) -eq 13 ]"
  [ "$_output" == "$expected" ]
}

failed_function() {
  local hoge=1
  local fuga=2

  [ $((hoge + fuga)) -eq 4 ]
  return
}

testcase_formatter_redefine_failed_function() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function"
  c="[ \$((hoge + fuga)) -eq 4 ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function ()
{
 local hoge=1;
 local fuga=2;
{ echo "${bashu_formatter_default_separator}"; echo [ \$((hoge + fuga)) -eq 4 ]; } >${fifo};
 [ \$((hoge + fuga)) -eq 4 ];
 return;
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_string() {
  local str="hello world"

  [ "$str" == "Hello World" ]
  return
}

testcase_formatter_redefine_failed_function_string() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_string"
  c="[ \"\$str\" == \"Hello World\" ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_string ()
{
 local str="hello world";
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\$str\"" == "\"Hello World\"" ]; } >${fifo};
 [ "\$str" == "Hello World" ];
 return;
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_single() {
  [ $((1 + 2)) -eq 4 ]
}

testcase_formatter_redefine_failed_function_single_command() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_single"
  c="[ \$((1 + 2)) -eq 4 ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_single ()
{
{ echo "${bashu_formatter_default_separator}"; echo [ \$((1 + 2)) -eq 4 ]; } >${fifo};
 [ \$((1 + 2)) -eq 4 ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_associative_array() {
  declare -A dict=([a]=1 [b]=2 [c]=3)
  [ "${dict[a]}" -eq 1 ]
  [ "${dict[b]}" -eq 2 ]
  [ "${dict[c]}" -eq 4 ]
}

testcase_formatter_redefine_failed_function_associative_array() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_associative_array"
  c="[ \"\${dict[c]}\" -eq 4 ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_associative_array ()
{
 declare -A dict=([a]=1 [b]=2 [c]=3);
 [ "\${dict[a]}" -eq 1 ];
 [ "\${dict[b]}" -eq 2 ];
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\${dict[c]}\"" -eq 4 ]; } >${fifo};
 [ "\${dict[c]}" -eq 4 ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_associative_array_expand() {
  declare -A dict=([a]=1 [b]=2 [c]=3)
  [ "${dict[*]}" == "1 2 4" ]
}

testcase_formatter_redefine_failed_function_associative_array_expand() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_associative_array_expand"
  c="[ \"\${dict[*]}\" == \"1 2 4\" ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_associative_array_expand ()
{
 declare -A dict=([a]=1 [b]=2 [c]=3);
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\${dict[*]}\"" == "\"1 2 4\"" ]; } >${fifo};
 [ "\${dict[*]}" == "1 2 4" ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_with_comments() {
  true
  false # comment
}

testcase_formatter_redefine_failed_function_with_comments() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_with_comments"
  c="false"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_with_comments ()
{
 true;
{ echo "${bashu_formatter_default_separator}"; echo false; } >${fifo};
 false;
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_multi_same_commands() {
  true
  false "hoge"
  true
  false "fuga"
  true
  false
  true
}

testcase_formatter_redefine_failed_function_multi_same_commands() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_multi_same_commands"
  c="false"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_multi_same_commands ()
{
 true;
{ echo "${bashu_formatter_default_separator}"; echo false "\"hoge\""; } >${fifo};
 false "hoge";
 true;
{ echo "${bashu_formatter_default_separator}"; echo false "\"fuga\""; } >${fifo};
 false "fuga";
 true;
{ echo "${bashu_formatter_default_separator}"; echo false; } >${fifo};
 false;
 true;
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_spaces_between_args() {
  local hoge=1
  local fuga=2

  [   $((hoge+fuga))   -eq   11  ]
}

testcase_formatter_redefine_failed_function_spaces_between_args() {
  local f c
  local fifo=fifo
  local _output
  local expected

  f="failed_function_spaces_between_args"
  c="[ \$((hoge+fuga)) -eq 11 ]"
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_spaces_between_args ()
{
 local hoge=1;
 local fuga=2;
{ echo "${bashu_formatter_default_separator}"; echo [ \$((hoge+fuga)) -eq 11 ]; } >${fifo};
 [ \$((hoge+fuga)) -eq 11 ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_spaces_between_args2() {
  local hoge=1
  local fuga=2

  [   $((  hoge  +  fuga  ))   -eq   13   ]
}

testcase_formatter_redefine_failed_function_spaces_between_args2() {
  local f c
  local fifo=fifo
  local _output
  local expected
  local lineno

  lineno=$(getlineno "$0" "\[   \$((  hoge  +  fuga  ))   -eq   13   \]")
  f="failed_function_spaces_between_args2"
  c=$(_bashu_formatter_normalize_command "$0" "$lineno")
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_spaces_between_args2 ()
{
 local hoge=1;
 local fuga=2;
{ echo "${bashu_formatter_default_separator}"; echo [ \$(( hoge + fuga )) -eq 13 ]; } >${fifo};
 [ \$(( hoge + fuga )) -eq 13 ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}

failed_function_same_commands() {
  local _output
  local expected

  _output="hello"
  expected="hello"
  [ "$_output" == "$expected" ]

  _output="world"
  expected="world"
  [ "$_output" == "$expected" ]

  _output="hello"
  expected="world"
  [ "$_output" == "$expected" ] # failed_function_same_commands

  _output="!"
  expected="!"
  [ "$_output" == "$expected" ]
}

testcase_formatter_redefine_failed_function_same_commands() {
  local f c
  local fifo=fifo
  local _output
  local expected
  local lineno

  lineno=$(getlineno "$0" "\[ \"\$_output\" == \"\$expected\" \] # failed_function_same_commands")
  f="failed_function_same_commands"
  c=$(_bashu_formatter_normalize_command "$0" "$lineno")
  _output=$(_bashu_formatter_redefine_failed_function "$f" "$c" "$fifo")
  expected=$(cat <<EOF
failed_function_same_commands ()
{
 local _output;
 local expected;
 _output="hello";
 expected="hello";
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\$_output\"" == "\"\$expected\"" ]; } >${fifo};
 [ "\$_output" == "\$expected" ];
 _output="world";
 expected="world";
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\$_output\"" == "\"\$expected\"" ]; } >${fifo};
 [ "\$_output" == "\$expected" ];
 _output="hello";
 expected="world";
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\$_output\"" == "\"\$expected\"" ]; } >${fifo};
 [ "\$_output" == "\$expected" ];
 _output="!";
 expected="!";
{ echo "${bashu_formatter_default_separator}"; echo [ "\"\$_output\"" == "\"\$expected\"" ]; } >${fifo};
 [ "\$_output" == "\$expected" ];
}
EOF
  )
  [ "$_output" == "$expected" ]
}



dummy_testcase() {
  false # dummy_testcase
}

testcase_formatter_summary_default_evaluate() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "false # dummy_testcase")
  err_info=("dummy_testcase" "dummy_testcase" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="false"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_compare_numerals() {
  local hoge=1
  local fuga=2

  [ $(( hoge + fuga )) -eq 4 ] # dummy_testcase_compare_numerals
}

testcase_formatter_summary_default_evaluate_compare_numerals() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ \$(( hoge + fuga )) -eq 4 \] # dummy_testcase_compare_numerals")
  err_info=("dummy_testcase_compare_numerals" "dummy_testcase_compare_numerals" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ 3 -eq 4 ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_compare_string() {
  local string="hello world"

  [ "$string" == "Hello World" ] # dummy_testcase_compare_string
}

testcase_formatter_summary_default_evaluate_compare_string() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ \"\$string\" == \"Hello World\" \] # dummy_testcase_compare_string")
  err_info=("dummy_testcase_compare_string" "dummy_testcase_compare_string" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ \"hello world\" == \"Hello World\" ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_compare_zero_string() {
  local string="hello world"

  [ -z "$string" ] # dummy_testcase_compare_zero_string
}

testcase_formatter_summary_default_evaluate_compare_zero_string() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ -z \"\$string\" \] # dummy_testcase_compare_zero_string")
  err_info=("dummy_testcase_compare_zero_string" "dummy_testcase_compare_zero_string" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ -z \"hello world\" ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_check_exit_status() {
  local arg1="hoge"
  local arg2="fuga"

  false "$arg1" "$arg2" # dummy_testcase_check_exit_status
}

testcase_formatter_summary_default_evaluate_check_exit_status() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "false \"\$arg1\" \"\$arg2\" # dummy_testcase_check_exit_status")
  err_info=("dummy_testcase_check_exit_status" "dummy_testcase_check_exit_status" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="false \"hoge\" \"fuga\""
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_same_commands() {
  local _output
  local expected

  _output="hello"
  expected="hello"
  [ "$_output" == "$expected" ]

  _output="world"
  expected="world"
  [ "$_output" == "$expected" ]

  _output="hello"
  expected="world"
  [ "$_output" == "$expected" ] # dummy_testcase_same_commands

  _output="!"
  expected="!"
  [ "$_output" == "$expected" ]
}

testcase_formatter_summary_default_evaluate_same_commands() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ \"\$_output\" == \"\$expected\" \] # dummy_testcase_same_commands")
  err_info=("dummy_testcase_same_commands" "dummy_testcase_same_commands" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ \"hello\" == \"world\" ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_spaces_between_args() {
  local hoge=1
  local fuga=2

  [   $((hoge+fuga))   -eq   11  ] # dummy_testcase_spaces_between_args
}

testcase_formatter_summary_default_evaluate_spaces_between_args() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[   \$((hoge+fuga))   -eq   11  \] # dummy_testcase_spaces_between_args")
  err_info=("dummy_testcase_spaces_between_args" "dummy_testcase_spaces_between_args" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ 3 -eq 11 ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_spaces_between_args2() {
  local hoge=1
  local fuga=2

  [   $((  hoge  +  fuga  ))   -eq   13   ] # dummy_testcase_spaces_between_args2
}

testcase_formatter_summary_default_evaluate_spaces_between_args2() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[   \$((  hoge  +  fuga  ))   -eq   13   \] # dummy_testcase_spaces_between_args2")
  err_info=("dummy_testcase_spaces_between_args2" "dummy_testcase_spaces_between_args2" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ 3 -eq 13 ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_command_substitution() {
  [ "$(printf "%s " "arg1" "arg2")" == "arg1 arg2" ] # dummy_testcase_command_substitution
}

testcase_formatter_summary_default_evaluate_command_substitution() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ \"\$(printf \"%s \" \"arg1\" \"arg2\")\" == \"arg1 arg2\" \] # dummy_testcase_command_substitution")
  err_info=("dummy_testcase_command_substitution" "dummy_testcase_command_substitution" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected="[ arg1 arg2  == arg1 arg2 ]"
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

dummy_testcase_multi_line_eval() {
  local doc
  local doc_expected

  doc=$(cat <<EOF
line #1
line #2
line #3
line #4
EOF
  )

  doc_expected=$(cat <<EOF
line #1
line #2
line #333
line #4
EOF
  )

  [ "$doc" == "$doc_expected" ] # dummy_testcase_multi_line_eval
}

testcase_formatter_summary_default_evaluate_multi_line_eval() {
  local _output
  local expected
  local err_info=()
  local fifo=/tmp/bashufifo-$BASHPID
  local lineno

  rm -f "$fifo"
  mkfifo "$fifo"
  lineno=$(getlineno "$0" "\[ \"\$doc\" == \"\$doc_expected\" \] # dummy_testcase_multi_line_eval")
  err_info=("dummy_testcase_multi_line_eval" "dummy_testcase_multi_line_eval" "$0" "$lineno")
  _output=$(_bashu_formatter_summary_default_evaluate "${err_info[@]}" "$fifo")
  expected=$(cat <<EOF
[ "line #1
line #2
line #3
line #4" == "line #1
line #2
line #333
line #4" ]
EOF
  )
  [ "$_output" == "$expected" ]
  rm -f "$fifo"
}

testcase_formatter_summary_default_when_failure() {
  local r=127
  local _output
  local expected

  setup
  _bashu_initialize

  _bashu_errtrap "$r" "$fd" 0 # testcase_formatter_summary_default_when_failure
  bashu_postprocess "$r" "$fd"

  local ln
  ln=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # testcase_formatter_summary_default_when_failure")
  bashu_is_running=0
  bashu_collected_testcases=("$bashu_current_test")
  bashu_total_execution_time=30
  COLUMNS=60
  bashu_dump_summary "$fd"
  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"

  local prefix="testcase_"
  expected=$(cat <<EOF

========================= FAILURES =========================
^[[1m^[[31m_____ testcase_formatter_summary_default_when_failure ______^[[m^O

    ${prefix}formatter_summary_default_when_failure() {
      local r=127
      local _output
      local expected

      setup
      _bashu_initialize

      _bashu_errtrap "\$r" "\$fd" 0 # testcase_formatter_summary_default_when_failure
>     _bashu_errtrap "\$r" "\$fd" 0 # testcase_formatter_summary_default_when_failure
^[[1m^[[31mE     _bashu_errtrap "$r" "$((fd+1))" 0^[[m^O

^[[1m^[[31m${0}^[[m^O:$ln: Exit with $r
^[[1m^[[31m1 failed^[[m^O^[[31m in 0.03s^[[m^O
EOF
  )
  [ "$_output" == "$expected" ]
  teardown
}

_testcase_formatter_summary_default_when_failure_nested2() {
  local r=$1

  _bashu_errtrap "$r" "$fd" 0 # _testcase_formatter_summary_default_when_failure_nested2
}

_testcase_formatter_summary_default_when_failure_nested() {
  local r=$1

  true
  _testcase_formatter_summary_default_when_failure_nested2 "$r"
}

testcase_formatter_summary_default_when_failure_nested() {
  local r=128
  local _output
  local expected

  setup
  _bashu_initialize

  _testcase_formatter_summary_default_when_failure_nested "$r"
  bashu_postprocess "$r" "$fd"

  local ln
  ln=$(getlineno "$0" "_bashu_errtrap \"\$r\" \"\$fd\" 0 # _testcase_formatter_summary_default_when_failure_nested2")
  bashu_is_running=0
  bashu_collected_testcases=("$bashu_current_test")
  bashu_total_execution_time=50
  COLUMNS=60
  bashu_dump_summary "$fd"
  read -r -u "$fd" v; eval "$v"
  _output="$(_bashu_formatter_default "$fd" | cat -v)"

  local prefix="testcase_"
  expected=$(cat <<EOF

========================= FAILURES =========================
^[[1m^[[31m__ testcase_formatter_summary_default_when_failure_nested __^[[m^O

    ${prefix}formatter_summary_default_when_failure_nested() {
      local r=128
      local _output
      local expected

      setup
      _bashu_initialize

      _testcase_formatter_summary_default_when_failure_nested "\$r"
>     _testcase_formatter_summary_default_when_failure_nested "\$r"
^[[1m^[[31mE   _testcase_formatter_summary_default_when_failure_nested() {
E     local r=\$1
E
E     true
E     _testcase_formatter_summary_default_when_failure_nested2 "\$r"
E+  _testcase_formatter_summary_default_when_failure_nested2() {
E+    local r=\$1
E+
E+    _bashu_errtrap "\$r" "\$fd" 0 # _testcase_formatter_summary_default_when_failure_nested2
E++   _bashu_errtrap "$r" "$((fd+1))" 0^[[m^O

^[[1m^[[31m${0}^[[m^O:$ln: Exit with $r
^[[1m^[[31m1 failed^[[m^O^[[31m in 0.05s^[[m^O
EOF
  )
  [ "$_output" == "$expected" ]
  teardown
}

bashu_main "$@"
