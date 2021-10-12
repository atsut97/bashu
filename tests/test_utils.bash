#!/bin/bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"


### set_color_palette

testcase_set_color_palette_8() {
  set_color_palette 8
  [ "${__palette[black]}"   -eq 0 ]
  [ "${__palette[maroon]}"  -eq 1 ]
  [ "${__palette[green]}"   -eq 2 ]
  [ "${__palette[olive]}"   -eq 3 ]
  [ "${__palette[navy]}"    -eq 4 ]
  [ "${__palette[purple]}"  -eq 5 ]
  [ "${__palette[teal]}"    -eq 6 ]
  [ "${__palette[silver]}"  -eq 7 ]
  [ "${__palette[grey]}"    -eq 0 ]
  [ "${__palette[red]}"     -eq 1 ]
  [ "${__palette[lime]}"    -eq 2 ]
  [ "${__palette[yellow]}"  -eq 3 ]
  [ "${__palette[blue]}"    -eq 4 ]
  [ "${__palette[fuchsia]}" -eq 5 ]
  [ "${__palette[aqua]}"    -eq 6 ]
  [ "${__palette[white]}"   -eq 7 ]
}

testcase_set_color_palette_16() {
  set_color_palette 16
  [ "${__palette[black]}"   -eq 0 ]
  [ "${__palette[maroon]}"  -eq 1 ]
  [ "${__palette[green]}"   -eq 2 ]
  [ "${__palette[olive]}"   -eq 3 ]
  [ "${__palette[navy]}"    -eq 4 ]
  [ "${__palette[purple]}"  -eq 5 ]
  [ "${__palette[teal]}"    -eq 6 ]
  [ "${__palette[silver]}"  -eq 7 ]
  [ "${__palette[grey]}"    -eq 8 ]
  [ "${__palette[red]}"     -eq 9 ]
  [ "${__palette[lime]}"    -eq 10 ]
  [ "${__palette[yellow]}"  -eq 11 ]
  [ "${__palette[blue]}"    -eq 12 ]
  [ "${__palette[fuchsia]}" -eq 13 ]
  [ "${__palette[aqua]}"    -eq 14 ]
  [ "${__palette[white]}"   -eq 15 ]
}

testcase_set_color_palette_256() {
  set_color_palette 256
  [ "${__palette[black]}"   -eq 0 ]
  [ "${__palette[maroon]}"  -eq 1 ]
  [ "${__palette[green]}"   -eq 2 ]
  [ "${__palette[olive]}"   -eq 3 ]
  [ "${__palette[navy]}"    -eq 4 ]
  [ "${__palette[purple]}"  -eq 5 ]
  [ "${__palette[teal]}"    -eq 6 ]
  [ "${__palette[silver]}"  -eq 7 ]
  [ "${__palette[grey]}"    -eq 8 ]
  [ "${__palette[red]}"     -eq 9 ]
  [ "${__palette[lime]}"    -eq 10 ]
  [ "${__palette[yellow]}"  -eq 11 ]
  [ "${__palette[blue]}"    -eq 12 ]
  [ "${__palette[fuchsia]}" -eq 13 ]
  [ "${__palette[aqua]}"    -eq 14 ]
  [ "${__palette[white]}"   -eq 15 ]
}


### colorize
testcase_colorize() {
  local _output
  local expected

  set_color_palette 8

  # black
  _output=$(colorize black "colored text" | cat -v)
  expected="^[[30mcolored text"
  [ "$_output" == "$expected" ]

  # red
  _output=$(colorize red "colored text" | cat -v)
  expected="^[[31mcolored text"
  [ "$_output" == "$expected" ]

  # green
  _output=$(colorize green "colored text" | cat -v)
  expected="^[[32mcolored text"
  [ "$_output" == "$expected" ]

  # yellow
  _output=$(colorize yellow "colored text" | cat -v)
  expected="^[[33mcolored text"
  [ "$_output" == "$expected" ]

  # blue
  _output=$(colorize blue "colored text" | cat -v)
  expected="^[[34mcolored text"
  [ "$_output" == "$expected" ]

  # magenta
  _output=$(colorize magenta "colored text" | cat -v)
  expected="^[[35mcolored text"
  [ "$_output" == "$expected" ]

  # cyan
  _output=$(colorize cyan "colored text" | cat -v)
  expected="^[[36mcolored text"
  [ "$_output" == "$expected" ]

  # white
  _output=$(colorize white "colored text" | cat -v)
  expected="^[[37mcolored text"
  [ "$_output" == "$expected" ]
}

testcase_colorize_pipe() {
  local _output
  local expected

  set_color_palette 8
  _output=$(echo "colored text" | colorize red | cat -v)
  expected="^[[31mcolored text"
  [ "$_output" == "$expected" ]
}


### horizln

testcase_horizln() {
  local _output
  local expected

  COLUMNS=40
  _output=$(horizln '=')
  expected="========================================"
  [ "$_output" == "$expected" ]
}

testcase_horizln_odd() {
  local _output
  local expected

  COLUMNS=41
  _output=$(horizln '_')
  expected="_________________________________________"
  [ "$_output" == "$expected" ]
}

testcase_horizln_text() {
  local _output
  local expected

  COLUMNS=40
  _output=$(horizln '-' 'Hello World')
  expected="------------- Hello World --------------"
  [ "$_output" == "$expected" ]
}

testcase_horizln_text_odd() {
  local _output
  local expected

  COLUMNS=37
  _output=$(horizln '.' 'Errors')
  expected=".............. Errors ..............."
  [ "$_output" == "$expected" ]
}

testcase_horizln_equal_length() {
  local _output
  local expected

  COLUMNS=28
  _output=$(horizln '-' 'Lorem ipsum dolor sit amet')
  expected=" Lorem ipsum dolor sit amet "
  [ "$_output" == "$expected" ]

  COLUMNS=27
  _output=$(horizln '-' 'Lorem ipsum dolor sit amet')
  expected="Lorem ipsum dolor sit amet "
  [ "$_output" == "$expected" ]

  COLUMNS=26
  _output=$(horizln '-' 'Lorem ipsum dolor sit amet')
  expected="Lorem ipsum dolor sit amet"
  [ "$_output" == "$expected" ]
}

testcase_horizln_long_text() {
  local _output
  local expected

  COLUMNS=40
  _output=$(horizln '-' 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
  expected="Lorem ipsum dolor sit amet, consectetuer adipiscing elit."
  [ "$_output" == "$expected" ]
}

testcase_horizln_with_colorize() {
  local _output
  local expected

  set_color_palette 8
  COLUMNS=40
  _output=$(horizln '=' 'ERRORS' | colorize red | cat -v)
  expected="^[[31m================ ERRORS ================"
  [ "$_output" == "$expected" ]
}


### error

testcase_error() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(error "this is an error message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[31merror^[[m^O: testcase_error: this is an error message."
  [ "$_output" == "$expected" ]
}

testcase_error_more() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(error "this is another error message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[31merror^[[m^O: testcase_error_more: this is another error message."
  [ "$_output" == "$expected" ]
}


### warn

testcase_warn() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(warn "this is a warning message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[34mwarning^[[m^O: testcase_warn: this is a warning message."
  [ "$_output" == "$expected" ]
}

testcase_warn_more() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(warn "this is another warning message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[34mwarning^[[m^O: testcase_warn_more: this is another warning message."
  [ "$_output" == "$expected" ]
}


### debug

testcase_debug() {
  local _output
  local expected

  is_debugging=1
  # Catch stderr only by swapping stdout and stderr.
  _output=$(debug "this is a debug message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[33mdebug^[[m^O: testcase_debug: this is a debug message."
  [ "$_output" == "$expected" ]
}

testcase_debug_more() {
  local _output
  local expected

  is_debugging=1
  # Catch stderr only by swapping stdout and stderr.
  _output=$(debug "this is another debug message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[33mdebug^[[m^O: testcase_debug_more: this is another debug message."
  [ "$_output" == "$expected" ]
}

testcase_debug_no_output() {
  local _output

  is_debugging=0
  # Catch stderr only by swapping stdout and stderr.
  _output=$(debug "this message is not shown." 3>&2 2>&1 1>&3-)
  [ -z "$_output" ]
}

### internal_error

testcase_internal_error() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(internal_error "this is an internal_error message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[31mbashu internal error^[[m^O: testcase_internal_error: this is an internal_error message."
  [ "$_output" == "$expected" ]
}

testcase_internal_error_more() {
  local _output
  local expected

  # Catch stderr only by swapping stdout and stderr.
  _output=$(internal_error "this is another internal_error message." 3>&2 2>&1 1>&3- | cat -v)
  expected="^[[31mbashu internal error^[[m^O: testcase_internal_error_more: this is another internal_error message."
  [ "$_output" == "$expected" ]
}


### print_var_defs

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


### copy_function

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


### extract_range_of_lines

testcase_extract_range_of_lines() {
  local data="$rootdir/tests/test_utils_data.bash"
  local _output
  local expected

  _output="$(extract_range_of_lines "$data" 10 14)"
  expected="$(sed -n '10,14p' "$data")"
  [ "$_output" == "$expected" ]
}

testcase_extract_range_of_lines_continue_with_backslash() {
  local data="$rootdir/tests/test_utils_data.bash"
  local _output
  local expected

  _output="$(extract_range_of_lines "$data" 21 26)"
  expected="$(sed -n '21,29p' "$data")"
  [ "$_output" == "$expected" ]
}

testcase_extract_range_of_lines_exact() {
  local data="$rootdir/tests/test_utils_data.bash"
  local _output
  local expected

  _output="$(extract_range_of_lines -exact "$data" 26 26)"
  expected="$(sed -n '26,26p' "$data")"
  [ "$_output" == "$expected" ]
}

testcase_extract_range_of_lines_continue_with_backslash_and_comment() {
  local data="$rootdir/tests/test_utils_data.bash"
  local _output
  local expected

  _output="$(extract_range_of_lines "$data" 32 37)"
  expected="$(sed -n '32,40p' "$data")"
  [ "$_output" == "$expected" ]
}

testcase_extract_range_of_lines_continue_with_backslash_and_comment_and_space() {
  local data="$rootdir/tests/test_utils_data.bash"
  local _output
  local expected

  _output="$(extract_range_of_lines "$data" 43 48)"
  expected="$(sed -n '43,55p' "$data")"
  [ "$_output" == "$expected" ]
}

testcase_extract_range_of_lines_error_no_such_file() {
  local data="$rootdir/tests/nonexists"
  local _output
  local expected
  local _status

  _output="$(extract_range_of_lines "$data" 10 14 2>&1 ||:)"
  expected="bashu error: extract_range_of_lines: ${data}: No such file or directory"
  [ "$_output" == "$expected" ]
  extract_range_of_lines "$data" 10 14 >/dev/null 2>&1 || _status=$?
  [ "$_status" -eq 2 ]
}

testcase_extract_range_of_lines_error_is_directory() {
  local data="$rootdir/tests"
  local _output
  local expected
  local _status

  _output="$(extract_range_of_lines "$data" 10 14 2>&1 ||:)"
  expected="bashu error: extract_range_of_lines: ${data}: Is a directory"
  [ "$_output" == "$expected" ]
  extract_range_of_lines "$data" 10 14 >/dev/null 2>&1 || _status=$?
  [ "$_status" -eq 21 ]
}


### extract_indent

testcase_extract_indent() {
  local _output # testcase_extract_indent
  local lineno

  lineno=$(grep -ne "local _output # testcase_extract_indent$" "$0" | cut -d':' -f1)
  _output=$(extract_indent "$0" "$lineno")
  [ "$_output" == "  " ]
}

### find_function_location

dummy_func() {
  :
}

dummy_func2() {
  :
}

testcase_find_function_location() {
  local _output
  local expected
  local lineno

  lineno="$(grep -n "^dummy_func(. {" test_utils.bash | cut -f1 -d':')"
  _output="$(find_function_location "dummy_func")"
  expected="$lineno $0"
  [ "$_output" == "$expected" ]
}

testcase_find_function_location_multiple() {
  local _output
  local expected
  local lineno

  lineno=""
  mapfile -t lineno < <(grep -n "^dummy_func.*(. {" test_utils.bash | cut -f1 -d':')
  _output="$(find_function_location "dummy_func" "dummy_func2")"
  expected="\
${lineno[0]} $0
${lineno[1]} $0"
  [ "$_output" == "$expected" ]
}

testcase_find_function_location_error() {
  local _output
  local expected
  local _status

  _output="$(find_function_location "no_such_function" 2>&1 ||:)"
  expected="bashu error: find_function_location: no_such_function: command not found"
  [ "$_output" == "$expected" ]
  find_function_location "no_such_function" >/dev/null 2>&1 || _status=$?
  [ "$_status" -eq 127 ]
}


### timer

testcase_timer() {
  local t

  timer_start
  sleep 0.1
  timer_stop t
  [ "$t" -gt 100 ]
  [ "$t" -lt 110 ]
}

testcase_multiple_timers() {
  local t

  # Spawn three timers.
  timer_start
  timer_start
  timer_start
  sleep 0.1

  # Stop the first timer.
  timer_stop t
  [ "$t" -gt 100 ]
  [ "$t" -lt 110 ]
  sleep 0.1

  # Stop the second.
  timer_stop t
  [ "$t" -gt 200 ]
  [ "$t" -lt 220 ]
  sleep 0.1

  # Stop the last.
  timer_stop t
  [ "$t" -gt 300 ]
  [ "$t" -lt 330 ]
}

testcase_multiple_timers_more() {
  local t

  # Start a timer.
  timer_start

  # Start a timer and stop it.
  timer_start
  sleep 0.1
  timer_stop t
  [ "$t" -gt 100 ]
  [ "$t" -lt 110 ]

  # Start another timer and stop it.
  timer_start
  sleep 0.1
  timer_stop t
  [ "$t" -gt 100 ]
  [ "$t" -lt 110 ]

  # Start a timer once again and stop it.
  timer_start
  sleep 0.1
  timer_stop t
  [ "$t" -gt 100 ]
  [ "$t" -lt 110 ]

  # Stop the first timer.
  timer_stop t
  [ "$t" -gt 300 ]
  [ "$t" -lt 340 ]
}

testcase_timer_error() {
  local t

  __timer_start_stack=()
  timer_start
  timer_stop t
  ! timer_stop t 2>/dev/null
}

testcase_timer_error_output() {
  local _output
  local t

  __timer_start_stack=()
  timer_start
  timer_stop t
  _output=$(timer_stop t 2>&1 ||:)
  [ "$(echo "$_output" | cat -v)" == "^[[31merror^[[m^O: timer_stop: No timers start" ]
}


bashu_main "$@"
