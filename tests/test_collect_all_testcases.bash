#!/usr/bin/env bash

# Change the current working directory to where this script exists to
# source `bashu` correctly.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# shellcheck source=../bashu
source ../bashu

testcase_test01() {
  true
}

testcase_test02_with_underscore(){
  true
}

testcase_test03-with-hyphen() {
  true
}

testcase_test04:with:colon() {
  true
}

  testcase_test05_spaces      ()  {
  true
}

function testcase_test06() {
  true
}

function testcase_test07_with_underscore (){
  true
}

  function testcase_test08_spaces   () {
    true
}

function testcase_test09_no_parens {
  true
}

# testcase_comment_01 (){
#   echo "PID=$$:${FUNCNAME[0]}:$LINENO"; true
# }

# function testcase_comment02 {
#   echo "PID=$$:${FUNCNAME[0]}:$LINENO"; true
# }

function not_testcase_test01 {
  true
}

function not_testcase_test02() {
  true
}

not_testcase_test03() {
  true
}

testcase_main() {
  [ ${#bashu_all_tests[@]} -eq 10 ]
  [ "${bashu_all_tests[0]}" = "testcase_test01" ]
  [ "${bashu_all_tests[1]}" = "testcase_test02_with_underscore" ]
  [ "${bashu_all_tests[2]}" = "testcase_test03-with-hyphen" ]
  [ "${bashu_all_tests[3]}" = "testcase_test04:with:colon" ]
  [ "${bashu_all_tests[4]}" = "testcase_test05_spaces" ]
  [ "${bashu_all_tests[5]}" = "testcase_test06" ]
  [ "${bashu_all_tests[6]}" = "testcase_test07_with_underscore" ]
  [ "${bashu_all_tests[7]}" = "testcase_test08_spaces" ]
  [ "${bashu_all_tests[8]}" = "testcase_test09_no_parens" ]
  [ "${bashu_all_tests[9]}" = "testcase_main" ]
}

bashu_main "$@"
